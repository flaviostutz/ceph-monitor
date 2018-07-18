#!/bin/bash
set -e
# set -x

echo ">>>> JOINING THIS MONITOR TO AN EXISTING CLUSTER..."

if [ "$FS_ID" == "" ]; then
    export FS_ID=$(uuidgen)
fi

if [ "$MONITOR_NAME" == "" ]; then
    export MONITOR_NAME=$(hostname)
fi

if [ "$MONITOR_HOST" == "" ]; then
    export MONITOR_HOST=$(hostname)
fi

if [ "$MONITOR_IP" == "" ]; then
    export MONITOR_IP=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
fi

if [ "$MONITOR_PORT" == "" ]; then
    export MONITOR_PORT=6789
fi


if [ ! -f /initialized ]; then 
    echo "Creating ceph.conf..."
    cat /ceph-join.conf.template | envsubst > /etc/ceph/ceph.conf
    cat /etc/ceph/ceph.conf
    mkdir -p /var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME

    echo "Retrieving CRUSH map..."
    while true; do
        ceph mon getmap -o /tmp/monmap && break
        echo "Retrying to connect to peer monitor ${JOIN_MONITOR_HOST} in 1 second..."
        sleep 1
    done
    
    ceph-mon --mkfs --monmap /tmp/monmap --debug_mon $LOG_LEVEL --id=$MONITOR_NAME --cluster=$CLUSTER_NAME --mon-data /var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME

    touch /var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME/done
    touch /initialized
else
    echo "Monitor already initialized before. Reusing state."
fi

echo ""
echo "Starting Ceph Monitor $CLUSTER_NAME-$MONITOR_NAME by retrieving data from another monitor at ${JOIN_MONITOR_HOST}..."
ceph-mon -d --public_addr ${MONITOR_IP}:${MONITOR_PORT} --debug_mon $LOG_LEVEL --id=$MONITOR_NAME --cluster=$CLUSTER_NAME

