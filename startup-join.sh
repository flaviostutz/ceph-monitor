#!/bin/bash
set -e
# set -x

echo ">>>> JOINING THIS MONITOR TO AN EXISTING CLUSTER..."

if [ ! -f $MONITOR_DATA_PATH/initialized ]; then 
    echo ">>> Joining existing cluster..."
    mkdir -p $MONITOR_DATA_PATH

    while true; do
        echo "Retrieving CRUSH map from ${PEER_MONITOR_HOST}..."
        ceph mon getmap -o /tmp/monmap --keyring /etc/ceph/keyring && break
        echo "Retrying to connect to peer monitor ${PEER_MONITOR_HOST} in 1 second..."
        sleep 1
    done
    set -e
    
    ceph-mon --mkfs --monmap /tmp/monmap --debug_mon $LOG_LEVEL --id=$MONITOR_NAME --cluster $CLUSTER_NAME --mon-data $MONITOR_DATA_PATH --keyring /etc/ceph/keyring

    touch $MONITOR_DATA_PATH/initialized
else
    echo ">>> Monitor already initialized before. Reusing state."
fi

echo "KEYRING:"
cat /etc/ceph/keyring

echo ""
echo "Starting Ceph Monitor $CLUSTER_NAME-$MONITOR_NAME..."
ceph-mon -d --debug_mon $LOG_LEVEL --mon-data ${MONITOR_DATA_PATH} --id $MONITOR_NAME --cluster $CLUSTER_NAME --keyring /etc/ceph/keyring
