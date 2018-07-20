#!/bin/bash
set -e
set -x

echo ">>>> PREPARING AND BOOTSTRAPING THIS MONITOR FOR A NEW CLUSTER..."

if [ "$MONITOR_NAME" == "" ]; then
    export MONITOR_NAME=$(hostname)
fi

MONITOR_DATA_PATH=/var/lib/ceph/mon/$CLUSTER_NAME-$MONITOR_NAME
echo "MONITOR_DATA_PATH=${MONITOR_DATA_PATH}"

echo "Creating ceph.conf..."
cat /ceph-bootstrap.conf.template | envsubst > /etc/ceph/ceph.conf
cat /etc/ceph/ceph.conf

if [ ! -f $MONITOR_DATA_PATH/initialized ]; then 
    echo ">>> First monitor run. Preparing monitor state..."
    mkdir -p $MONITOR_DATA_PATH

    echo "Generating cluster keys..."
    echo ""
    #http://docs.ceph.com/docs/master/rados/configuration/auth-config-ref/
    ceph-authtool --create-keyring /tmp/keyring --gen-key -n mon. --cap mon 'allow *'
    ceph-authtool /tmp/keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow' --cap mgr 'allow'

    if [ ! "${ETCD_URL}" == "" ]; then
        echo "Sending keys to ETCD..."
        while true; do
            etcdctl --endpoints $ETCD_URL ls / && break
            echo "Retrying to connect to etcd at $ETCD_URL..."
            sleep 1
        done
        set +e
        etcdctl --endpoints $ETCD_URL mkdir $CLUSTER_NAME
        set -e
        KEYRING=$(cat /tmp/keyring | base64)
        etcdctl --endpoints $ETCD_URL set "/$CLUSTER_NAME/keyring" "${KEYRING}"
    fi

    echo "Creating CRUSH map..."
    if [ "$FS_ID" == "" ]; then
        export FS_ID=$(uuidgen)
        echo "FS_ID=$FS_ID"
    fi
    if [ "$MONITOR_IP" == "" ]; then
        export MONITOR_IP=$(ip route get 8.8.8.8 | grep -oE 'src ([0-9\.]+)' | cut -d ' ' -f 2)
    fi
    if [ "$MONITOR_PORT" == "" ]; then
        export MONITOR_PORT=6789
    fi
    monmaptool --create --add $MONITOR_NAME ${MONITOR_IP}:${MONITOR_PORT} --fsid ${FS_ID} /tmp/monmap
    ceph-mon --mkfs --mon-data $MONITOR_DATA_PATH --monmap /tmp/monmap --debug_mon $LOG_LEVEL --id $MONITOR_NAME --cluster $CLUSTER_NAME --keyring /tmp/keyring
    cp /tmp/keyring $MONITOR_DATA_PATH/keyring
    cp /tmp/keyring /etc/ceph/keyring
    
    touch $MONITOR_DATA_PATH/initialized
else
    echo ">>> Monitor already initialized before. Reusing state."
fi

echo ""
echo "Starting Ceph Monitor $CLUSTER_NAME-$MONITOR_NAME..."
ceph-mon -d --debug_mon $LOG_LEVEL --mon-data $MONITOR_DATA_PATH --id $MONITOR_NAME --cluster $CLUSTER_NAME --keyring $MONITOR_DATA_PATH/keyring

