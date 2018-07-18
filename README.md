# ceph-monitor
Docker image for running a Ceph Monitor daemon

# Usage

docker-compose.yml for a single monitor configuration

```
version: '3.5'

services:

  mon1:
    image: flaviostutz/ceph-monitor:latest
    environment:
        - LOG_LEVEL=5

```

docker-compose.yml for HA configuration

```
version: '3.5'

services:

  mon1:
    image: flaviostutz/ceph-monitor:latest
    environment:
      - LOG_LEVEL=10

  mon2:
    image: flaviostutz/ceph-monitor:latest
    environment:
      - LOG_LEVEL=10
      - JOIN_MONITOR_HOST=mon1

  mon3:
    image: flaviostutz/ceph-monitor:latest
    environment:
      - LOG_LEVEL=10
      - JOIN_MONITOR_HOST=mon2

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
