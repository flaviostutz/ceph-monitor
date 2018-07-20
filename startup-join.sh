#!/bin/bash
set -e
set -x

echo ">>>> JOINING THIS MONITOR TO AN EXISTING CLUSTER..."

if [ "$MONITOR_NAME" == "" ]; then
    export MONITOR_NAME=$(hostname)
fi

MONITOR_DATA_PATH=/var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME
echo "MONITOR_DATA_PATH=${MONITOR_DATA_PATH}"

echo "Creating ceph.conf..."
cat /ceph-join.conf.template | envsubst > /etc/ceph/ceph.conf
cat /etc/ceph/ceph.conf

if [ ! -f $MONITOR_DATA_PATH/initialized ]; then 
    echo ">>> First monitor run. Joining existing cluster..."
    mkdir -p $MONITOR_DATA_PATH

    echo "Retrieving monitor key..."
    ceph-authtool --create-keyring --gen-key /tmp/keyring
    while true; do
        # etcdctl --endpoints $ETCD_URL get /$CLUSTER_NAME/client.admin.keyring && break
        etcdctl --endpoints $ETCD_URL get /$CLUSTER_NAME/keyring && break
        echo "Retrying to connect to etcd at $ETCD_URL..."
        sleep 1
    done
    KEYRING=$(etcdctl --endpoints $ETCD_URL get "/$CLUSTER_NAME/keyring")
    echo $KEYRING > /tmp/base64keyring
    base64 -d -i /tmp/base64keyring > /tmp/keyring

    while true; do
        echo "Retrieving CRUSH map..."
        ceph mon getmap -o /tmp/monmap --keyring /tmp/keyring && break
        echo "Retrying to connect to peer monitor ${PEER_MONITOR_HOST} in 1 second..."
        sleep 1
    done
    
    ceph-mon --mkfs --monmap /tmp/monmap --debug_mon $LOG_LEVEL --id=$MONITOR_NAME --cluster $CLUSTER_NAME --mon-data $MONITOR_DATA_PATH --keyring /tmp/keyring
    cp /tmp/keyring $MONITOR_DATA_PATH/keyring
    cp /tmp/keyring /etc/ceph/keyring

    touch $MONITOR_DATA_PATH/initialized
else
    echo ">>> Monitor already initialized before. Reusing state."
fi

echo ""
echo "Starting Ceph Monitor $CLUSTER_NAME-$MONITOR_NAME by retrieving data from another monitor at ${PEER_MONITOR_HOST}..."
if [ "$MONITOR_IP" == "" ]; then
    export MONITOR_IP=$(ip route get 8.8.8.8 | grep -oE 'src ([0-9\.]+)' | cut -d ' ' -f 2)
fi
if [ "$MONITOR_PORT" == "" ]; then
    export MONITOR_PORT=6789
fi
ceph-mon -d --public_addr ${MONITOR_IP}:${MONITOR_PORT} --debug_mon $LOG_LEVEL --mon-data ${MONITOR_DATA_PATH} --id $MONITOR_NAME --cluster $CLUSTER_NAME --keyring $MONITOR_DATA_PATH/keyring
