FROM angelsevillacamins/kubernetes-spark-libraries:latest

MAINTAINER a.sevilla@anchormen.nl

ENV RSTUDIO_SERVER_VERSION 1.1.383
ENV PATH=/usr/lib/rstudio-server/bin:$PATH
# `Z_VERSION` will be updated by `dev/change_zeppelin_version.sh` 
ENV Z_VERSION="0.7.3" 
ENV LOG_TAG="[ZEPPELIN_${Z_VERSION}]:" \ 
    Z_HOME="/zeppelin" 
ENV MASTER spark://spark-master:7077

## Symlink pandoc & standard pandoc templates for use system-wide 
RUN wget -q http://download2.rstudio.org/rstudio-server-${RSTUDIO_SERVER_VERSION}-amd64.deb \
  && dpkg -i rstudio-server-${RSTUDIO_SERVER_VERSION}-amd64.deb \
  && rm rstudio-server-*-amd64.deb \
  && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
  && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
  && git clone https://github.com/jgm/pandoc-templates \
  && mkdir -p /opt/pandoc/templates \
  && cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* \
  && mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

## Need to configure non-root user for RStudio
RUN useradd rstudio \
  && echo "rstudio:rstudio" | chpasswd \
  && mkdir /home/rstudio \
  && chown rstudio:rstudio /home/rstudio \
  && addgroup rstudio staff

## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package \
RUN echo 'rsession-which-r=/usr/bin/R' >> /etc/rstudio/rserver.conf
  
## use more robust file locking to avoid errors when using shared volumes: 
RUN echo 'lock-type=advisory' >> /etc/rstudio/file-locks
  
## configure git not to request password each time 
RUN git config --system credential.helper 'cache --timeout=3600' \
  && git config --system push.default simple 

COPY userconf.sh /
RUN chmod +x /userconf.sh

## Zeppelin
RUN echo "$LOG_TAG Download Zeppelin binary" && \
    wget -q -O /tmp/zeppelin-${Z_VERSION}-bin-all.tgz http://archive.apache.org/dist/zeppelin/zeppelin-${Z_VERSION}/zeppelin-${Z_VERSION}-bin-all.tgz && \
    tar -zxvf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    rm -rf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    mv /zeppelin-${Z_VERSION}-bin-all ${Z_HOME}
RUN echo "$LOG_TAG Cleanup" && \
    apt-get autoclean && \
    apt-get clean

ENV ZEPPELIN_PORT 8181
ENV ZEPPELIN_NOTEBOOK_DIR /persist/zeppelin
ENV SPARK_SUBMIT_OPTIONS '--conf spark.driver.maxResultSize=${SPARK_DRIVER_MAXRESULTSIZE} --conf spark.driver.cores=${SPARK_DRIVER_CORES}'

## Add Zeppelin config files 
COPY shiro.ini /zeppelin/conf/

## Supervisor
RUN apt-get -y update \
  && apt-get install -y --no-install-recommends \
  supervisor

## Add conf files and log folder [to be used by supervisord]
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/spark-master
RUN mkdir -p /var/log/rstudio/
RUN mkdir -p /var/log/zeppelin/

CMD ["/usr/bin/supervisord"]