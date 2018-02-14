FROM angelsevillacamins/docker-hadoop:2.7.2

MAINTAINER a.sevilla@anchormen.nl

ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data
RUN mkdir -p /hadoop/dfs/data
VOLUME /hadoop/dfs/data

ADD run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
