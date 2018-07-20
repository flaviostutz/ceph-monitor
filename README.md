# ceph-monitor
Docker image for running a Ceph Monitor daemon

# Usage

docker-compose.yml for a single monitor configuration

```
version: '3.5'

services:

  mon1:
    image: flaviostutz/ceph-monitor
    environment:
        - LOG_LEVEL=5

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

  mon2:
    build: flaviostutz/ceph-monitor
    environment:
      - LOG_LEVEL=0
      - PEER_MONITOR_HOST=mon1
      - ETCD_URL=http://etcd0:2379

  mon3:
    build: flaviostutz/ceph-monitor
    environment:
      - LOG_LEVEL=0
      - PEER_MONITOR_HOST=mon2
      - ETCD_URL=http://etcd0:2379

volumes:
  etcd0:

```


### Environment options

* All ENVs are optional

* See parameter details at 
http://docs.ceph.com/docs/master/rados/configuration/mon-config-ref/

```
ENV CLUSTER_NAME 'ceph'
ENV FS_ID '' # defaults to hostname
ENV MONITOR_NAME '' # defaults to hostname
ENV MONITOR_HOST '' # defaults to hostname
ENV MONITOR_IP '' # defaults to local ip
ENV MONITOR_PORT 6789
ENV OSD_JOURNAL_SIZE 1024
ENV OSD_POOL_DEFAULT_SIZE 3
ENV OSD_POOL_DEFAULT_MIN_SIZE 2
ENV OSD_POOL_DEFAULT_PG_NUM 333
ENV OSD_CRUSH_CHOOSELEAF_TYPE 1
ENV LOG_LEVEL 3
```

### Attention
* The image doesn't support cephx authentication (yet)
