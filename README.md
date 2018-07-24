# ceph-monitor
Docker image for running a Ceph Monitor daemon

ETCD is used by different the instances so they can exchange the keyring. The first container to bootstrap the cluster will set the key and the others will retrieve the keyring from ETCD so they can connect to the peer monitor and and retrieve the monmap and join the cluster.

When container hostname or ip gets changed, another monitor instance will be joined to the cluster, as described in http://docs.ceph.com/docs/master/rados/operations/add-or-rm-mons/

The usage of volumes is not required, but may help you in case you need a hard recovery so it is recommended in production.

# Usage

docker-compose.yml for a single monitor configuration. After bootstrap, get the keyring file in container logs so that you can connect another services to this monitor (OSD, MGR etc)

```
version: '3.5'

services:

  mon1:
    image: flaviostutz/ceph-monitor
    ports:
      - 6789
```

docker-compose.yml for HA configuration

```
version: '3.5'

services:

  #etcd is used only to exchange client.admin key between monitor instances
  etcd0:
    image: quay.io/coreos/etcd
    volumes:
      - etcd0:/etcd_data
    environment:
      - ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
      - ETCD_ADVERTISE_CLIENT_URLS=http://etcd0:2379

  mon1:
    build: flaviostutz/ceph-monitor
    ports:
      - 6789:6789
    environment:
      - LOG_LEVEL=0
      - ETCD_URL=http://etcd0:2379
    volumes:
      - mon1:/var/lib/ceph/mon

  mon2:
    build: flaviostutz/ceph-monitor
    environment:
      - LOG_LEVEL=0
      - PEER_MONITOR_HOST=mon1
      - ETCD_URL=http://etcd0:2379
    volumes:
      - mon2:/var/lib/ceph/mon

  mon3:
    build: flaviostutz/ceph-monitor
    environment:
      - LOG_LEVEL=0
      - PEER_MONITOR_HOST=mon2
      - ETCD_URL=http://etcd0:2379
    volumes:
      - mon3:/var/lib/ceph/mon

volumes:
  etcd0:
  mon1:
  mon2:
  mon3:

```


### Environment options

* All ENVs are optional

* See parameter details at 
http://docs.ceph.com/docs/master/rados/configuration/mon-config-ref/

```
ENV CLUSTER_NAME 'ceph'
ENV FS_ID '' # defaults to hostname
ENV MONITOR_HOST '' # defaults to hostname
ENV MONITOR_IP '' # defaults to local ip
ENV MONITOR_NAME '' # defaults to hostname + ip + port
ENV MONITOR_PORT 6789
ENV LOG_LEVEL 3
```

