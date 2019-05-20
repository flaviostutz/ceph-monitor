FROM flaviostutz/ceph-base:13.2.5.2

ENV CLUSTER_NAME 'ceph'
ENV PEER_MONITOR_HOSTS ''
ENV PEER_MONITOR_ADDRESSES ''
ENV FS_ID ''
ENV MONITOR_NAME ''
ENV MONITOR_ADVERTISE_IP ''
ENV MONITOR_ADVERTISE_PORT 6789
#0.0.0.0 is important because the kernel was hanging when using IP explicitly
ENV MONITOR_BIND_IP '0.0.0.0'
ENV MONITOR_BIND_PORT 6789
ENV ETCD_URL ''
ENV CREATE_CLUSTER 'false'
ENV LOG_LEVEL 0

ADD startup.sh /
ADD startup-bootstrap.sh /
ADD startup-join.sh /
ADD ceph.conf.template /

EXPOSE 6789

VOLUME [ "/var/lib/ceph/mon" ]

CMD [ "/startup.sh" ]


