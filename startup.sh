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
        echo "Retrieving monitor key from ETCD..."
        KEYRING=$(etcdctl --endpoints $ETCD_URL get "/$CLUSTER_NAME/keyring")
        if [ $? -eq 0 ]; then
            echo $KEYRING > /tmp/base64keyring
            base64 -d -i /tmp/base64keyring > /etc/ceph/keyring
            cat /etc/ceph/keyring
            return 0
        else
            return 2
        fi
    else
        echo "Monitor key doesn't exist and ETCD was not defined. Cannot retrieve keys."
        return 1
    fi
}

if [ "$CREATE_CLUSTER_IF_PEER_DOWN" == "true" ]; then
    for i in `seq 1 5`; do
        set +e
        echo "Downloading keys from etcd..."
        resolveKeyring
        echo "Trying to contact another peer..."
        ceph mon getmap -o /tmp/monmap --connect-timeout 1000
        if [ $? -eq 0 ]; then
            set -e
            echo "Could contact peer. Joining it."
            ./startup-join.sh
        else
            set -e
            if [ $i -eq 5 ]; then
                echo "Could not contact peer. Creating a new cluster."
                ./startup-bootstrap.sh
                break
            else 
                echo "Retrying to connect to peer monitor ${PEER_MONITOR_HOST} in 1 second..."
                sleep 1
            fi
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

