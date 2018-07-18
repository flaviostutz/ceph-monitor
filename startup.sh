#!/bin/bash
set -e
# set -x

echo "Defining default values for ENVs..."
if [ "$CLUSTER_NAME" == "" ]; then
    echo "CLUSTER_NAME cannot be empty"
    exit 1
fi

if [ "$JOIN_MONITOR_HOST" == "" ]; then
    ./startup-bootstrap.sh

else
    ./startup-join.sh
fi

