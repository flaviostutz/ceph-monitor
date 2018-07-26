FROM flaviostutz/ceph-base:ubuntu-mimic-13.2.0.2

ENV CLUSTER_NAME 'ceph'
ENV PEER_MONITOR_HOST ''
ENV FS_ID ''
ENV MONITOR_NAME ''
ENV MONITOR_HOST ''
ENV MONITOR_IP ''
ENV MONITOR_PORT 6789
ENV ETCD_URL ''
ENV CREATE_CLUSTER 'false'
ENV CREATE_CLUSTER_IF_PEER_DOWN 'false'
ENV PEER_CONNECT_TIMEOUT 30
ENV LOG_LEVEL 0

ADD startup.sh /
ADD startup-bootstrap.sh /
ADD startup-join.sh /
ADD ceph.conf.template /

EXPOSE 6789

VOLUME [ "/var/lib/ceph/mon" ]

CMD [ "/startup.sh" ]


