#!/bin/bash
set -e
# set -x

echo ">>>> PREPARING AND BOOTSTRAPING THIS MONITOR FOR A NEW CLUSTER..."

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
    export MONITOR_IP=$(ip route get 8.8.8.8 | grep -oE 'src ([0-9\.]+)' | cut -d ' ' -f 2)
fi

if [ "$MONITOR_PORT" == "" ]; then
    export MONITOR_PORT=6789
fi

if [ "$OSD_POOL_DEFAULT_MIN_SIZE" == "" ]; then
    export OSD_POOL_DEFAULT_MIN_SIZE=0
fi 

if [ "$OSD_CRUSH_CHOOSELEAF_TYPE" == "" ]; then
    export OSD_CRUSH_CHOOSELEAF_TYPE=1
fi 


if [ ! -f /initialized ]; then 
    echo "Creating ceph.conf..."
    cat /ceph-bootstrap.conf.template | envsubst > /etc/ceph/ceph.conf
    cat /etc/ceph/ceph.conf
    mkdir -p /var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME

    echo "Creating CRUSH map..."
    monmaptool --create --add $MONITOR_NAME ${MONITOR_IP}:${MONITOR_PORT} --fsid $FS_ID /tmp/monmap
    ceph-mon --mkfs --monmap /tmp/monmap --debug_mon $LOG_LEVEL --id=$MONITOR_NAME --cluster=$CLUSTER_NAME --mon-data /var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME
    
    touch /var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME/done
    touch /initialized

else
    echo "Monitor already initialized before. Reusing state."
fi

echo ""
echo "Starting Ceph Monitor $CLUSTER_NAME-$MONITOR_NAME..."
ceph-mon -d --debug_mon $LOG_LEVEL --id=$MONITOR_NAME --cluster=$CLUSTER_NAME

