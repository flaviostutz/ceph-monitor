#!/bin/bash
set -e
# set -x

echo "CLUSTER_NAME=$CLUSTER_NAME; PEER_MONITOR_HOST=$PEER_MONITOR_HOST; CREATE_CLUSTER=$CREATE_CLUSTER; ETCD_URL=$ETCD_URL"

if [ "$CLUSTER_NAME" == "" ]; then
    echo "CLUSTER_NAME cannot be empty"
    exit 1
fi

if [ "$PEER_MONITOR_HOST" == "" ]; then
    if [ ! "$CREATE_CLUSTER" == "true" ]; then
        echo "Either PEER_MONITOR_HOST must be defined or CREATE_CLUSTER must be true"
        exit 2
    fi
else
    if [ ! "$CREATE_CLUSTER" == "true" ]; then
        if [ "$ETCD_URL" == "" ]; then
            echo "You specified a PEER_MONITOR_HOST but no ETCD_URL to retrieve keys and this instance is not meant to create a cluster (CREATE_CLUSTER is not true)"
            exit 3
        fi
    fi
fi

export LOCAL_IP=$(ip route get 8.8.8.8 | grep -oE 'src ([0-9\.]+)' | cut -d ' ' -f 2)
if [ "$MONITOR_ADVERTISE_IP" == "" ]; then
    export MONITOR_ADVERTISE_IP=$LOCAL_IP
fi
echo "MONITOR_ADVERTISE_IP=$MONITOR_ADVERTISE_IP"

if [ "$MONITOR_ADVERTISE_PORT" == "" ]; then
    export MONITOR_ADVERTISE_PORT=6789
fi
echo "MONITOR_ADVERTISE_PORT=$MONITOR_ADVERTISE_PORT"

if [ "$MONITOR_NAME" == "" ]; then
    export MONITOR_NAME=$(hostname):$MONITOR_ADVERTISE_IP:${MONITOR_ADVERTISE_PORT}
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
            echo "Keyring in base64:"
            echo "===="
            cat /tmp/base64keyring
            echo "===="
            echo "Key retrieved from etcd successfuly"
            return 0
        elif [ $? -eq 1 ]; then 
            echo "Etcd contacted, but key doesn't exists yet"
            return 2
        elif [ $? -eq 4 ]; then 
            echo "Couldn't contact server"
            return 4
        else
            echo "Error $?"
            return 9
        fi
    else
        echo "Monitor key doesn't exist in this instance and ETCD was not defined. Cannot retrieve keys."
        return 1
    fi
}

while true; do
    set +e
    resolveKeyring
    KR=$?
    if [ $KR -eq 0 ]; then
        ./startup-join.sh
        break
    elif [ $KR -eq 1 ]; then
        #Monitor key doesn't exist in this instance and ETCD was not defined
        if [ "$CREATE_CLUSTER" == "true" ]; then
            echo "Seems like cluster was not initialized before. Creating new cluster"
            ./startup-bootstrap.sh
            break
        else
            echo "This instance is not meant to create a new cluster and no key can be retrieved. Aborting."
            exit 5
        fi
    elif [ $KR -eq 2 ]; then
        #Etcd contacted, but key doesn't exists yet
        if [ "$CREATE_CLUSTER" == "true" ]; then
            echo "Seems like cluster was not initialized before. Creating new cluster"
            ./startup-bootstrap.sh
            break
        else
            #maybe another instance will create the keys soon (it will create the cluster)
            echo "Retrying in 1s..."
            sleep 1
        fi
    else
        echo "Retrying in 1s..."
        sleep 1
    fi
done

