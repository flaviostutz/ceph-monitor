FROM flaviostutz/ceph-base:latest

ENV CLUSTER_NAME 'ceph'
ENV PEER_MONITOR_HOST ''
ENV FS_ID ''
ENV MONITOR_NAME ''
ENV MONITOR_HOST ''
ENV MONITOR_IP ''
ENV MONITOR_PORT 6789
ENV ETCD_URL 'http://etcd0:2379'

ADD startup.sh /
ADD startup-bootstrap.sh /
ADD startup-join.sh /
ADD ceph-bootstrap.conf.template /
ADD ceph-join.conf.template /

EXPOSE 6789

VOLUME [ "/var/lib/ceph/mon" ]

CMD [ "/startup.sh" ]


