# FROM flaviostutz/ceph-base:latest
FROM cd319cebcf35

ENV CLUSTER_NAME 'ceph'
ENV JOIN_MONITOR_HOST ''
ENV FS_ID ''
ENV MONITOR_NAME ''
ENV MONITOR_HOST ''
ENV MONITOR_IP ''
ENV MONITOR_PORT 6789
ENV OSD_JOURNAL_SIZE 1024
ENV OSD_POOL_DEFAULT_SIZE 3
ENV OSD_POOL_DEFAULT_MIN_SIZE 2
ENV OSD_POOL_DEFAULT_PG_NUM 333
ENV OSD_CRUSH_CHOOSELEAF_TYPE 1
ENV LOG_LEVEL 3

ADD startup.sh /
ADD startup-bootstrap.sh /
ADD startup-join.sh /
ADD startup.sh /
ADD ceph-bootstrap.conf.template /
ADD ceph-join.conf.template /

EXPOSE 6789

CMD [ "/startup.sh" ]


