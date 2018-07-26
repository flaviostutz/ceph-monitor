#!/bin/bash
set -e
# set -x

if [ "$CLUSTER_NAME" == "" ]; then
    echo "CLUSTER_NAME cannot be empty"
    exit 1
fi

if [ "$MONITOR_IP" == "" ]; then
    export MONITOR_IP=$(ip route get 8.8.8.8 | grep -oE 'src ([0-9\.]+)' | cut -d ' ' -f 2)
fi
echo "MONITOR_IP=$MONITOR_IP"

if [ "$MONITOR_PORT" == "" ]; then
    export MONITOR_PORT=6789
fi
echo "MONITOR_PORT=$MONITOR_PORT"

if [ "$MONITOR_NAME" == "" ]; then
    export MONITOR_NAME=$(hostname):$MONITOR_IP:${MONITOR_PORT}
fi
echo "MONITOR_NAME=$MONITOR_NAME"

export MONITOR_DATA_PATH=/var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME
echo "MONITOR_DATA_PATH=${MONITOR_DATA_PATH}"

echo "Creating ceph.conf..."
cat /ceph.conf.template | envsubst > /etc/ceph/ceph.conf
cat /etc/ceph/ceph.conf

resolveKeyring() {
    if [ -f /etc/ceph/keyring ]; then
        echo "Monitor key already known"
        return 0
    elif [ "$ETCD_URL" != "" ]; then 
        echo "Retrieving monitor key from $ETCD_URL..."
        KEYRING=$(etcdctl --endpoints $ETCD_URL get "/$CLUSTER_NAME/keyring")
        if [ $? -eq 0 ]; then
            echo $KEYRING > /tmp/base64keyring
            base64 -d -i /tmp/base64keyring > /etc/ceph/keyring
            echo "Key retrieved from etcd successfuly"
            return 0
        elif [ $? -eq 1 ]; then 
            echo "Server contacted, by key doesn't exists"
            return 2
        elif [ $? -eq 4 ]; then 
            echo "Couldn't contact server"
            return 4
        else
            echo "Error $?"
            return 9
        fi
    else
        echo "Monitor key doesn't exist and ETCD was not defined. Cannot retrieve keys."
        return 1
    fi
}

if [ "$PEER_MONITOR_HOST" == "" ]; then
    echo "No peer configured."
    ./startup-bootstrap.sh

elif [ "$CREATE_CLUSTER" == "true" ]; then
    while true; do
        set +e
        resolveKeyring
        if [ $? -eq 0 ]; then
            for i in `seq 1 ${PEER_CONNECT_TIMEOUT}`; do
                echo "Trying to contact another peer..."
                ceph mon getmap -o /tmp/monmap --connect-timeout 1
                if [ $? -eq 0 ]; then
                    set -e
                    echo "Could contact peer. Joining it."
                    ./startup-join.sh
                else
                    set -e
                    if [ $i -eq ${PEER_CONNECT_TIMEOUT} ]; then
                        if [ "$CREATE_CLUSTER_IF_PEER_DOWN" == "true" ]; then
                            echo "Could not contact peer. Creating a new cluster."
                            ./startup-bootstrap.sh
                            break
                        else
                            echo "Cluster seems to be initialized before, but peer monitor could not be contacted. Exiting."
                        fi
                    else 
                        echo "Retrying to connect to peer monitor ${PEER_MONITOR_HOST} in 1 second..."
                        sleep 1
                    fi
                fi
            done
        elif [ $? -eq 2 ]; then
            echo "Seems like cluster was not initialized before. Creating new cluster"
            ./startup-bootstrap.sh
            break
        else
            echo "Retrying in 1s..."
            sleep 1
        fi
    done

else
    while true; do
        resolveKeyring && break
        echo "Retrying in 1s..."
        sleep 1
    done
    ./startup-join.sh
fi

