FROM ubuntu:16.04

MAINTAINER a.sevilla@anchormen.nl

ENV SPARK_VERSION 2.2.0
ENV R_BASE_VERSION 3.4.3
ENV ANACONDA_VERSION 5.0.1

RUN apt-get -y update \
	&& apt-get install -y --no-install-recommends \
		apt-transport-https \
		ca-certificates \
		curl \
		default-jdk \
		ed \
		file \
		fonts-texgyre \
		git \
		less \
		libapparmor1 \
		# To install httr package, the following library is needed 
		libcurl4-openssl-dev \
		libedit2 \
		# To install rgdal package, the following library is needed
		libgdal-dev \
		# To install rgeos package, the following library is needed
		libgeos-dev \
		# To install RPostgreSQL package, the following library is needed
		libpq-dev \
		# To install rgdal package, the following library is needed
		libproj-dev \
		# To install git2r package, the following libraries are needed
		libssh2-1 \
		libssh2-1-dev \
		# To install httr package, the following library is needed
		libssl-dev \
		# To install package xml2, the following library is needed
		libxml2-dev \
		locales \
		lsb-release \
		nano \
		openconnect \
		openssh-client \
		psmisc \
		python-setuptools \
		software-properties-common \
		sudo \
		unzip \
		vim-tiny \
		wget \
	&& rm -rf /var/lib/apt/lists/*  

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8
	
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Spark
RUN mkdir -p /opt \
    && cd /opt \
    && curl https://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz | tar -zx \
    && ln -s spark-${SPARK_VERSION}-bin-hadoop2.7 spark  \
    && echo Spark ${SPARK_VERSION} installed in /opt


ADD start-common.sh start-worker.sh start-master.sh /
RUN chmod +x /start-common.sh /start-master.sh /start-worker.sh

ENV JAVA_HOME /usr/lib/jvm/default-java
ENV PATH $PATH:/opt/spark/bin
ENV SPARK_HOME /opt/spark

# R
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
	&& add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/' \
	&& apt-get update -y \
	&& apt-get install -y --no-install-recommends \
		r-base=${R_BASE_VERSION}* \
		r-base-dev=${R_BASE_VERSION}* \
		r-recommended=${R_BASE_VERSION}* \
        && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/* \
	&& R -e "install.packages('devtools')"
    
ENV R_HOME /usr/lib/R

# Install additional R packages from CRAN or github

# For Zeppelin
RUN R -e "install.packages(c('knitr', 'ggplot2', 'googleVis', 'data.table', 'Rcpp'))" 
RUN R -e "devtools::install_github('ramnathv/rCharts')"

# Time Series Forecast
RUN R -e "devtools::install_github('robjhyndman/forecast')"

# PCA Analysis
RUN R -e "install.packages('factoextra')" 

# Python 3.6 and ANACONDA

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \ 
	wget --quiet https://repo.continuum.io/archive/Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh -O ~/anaconda.sh && \ 
	/bin/bash ~/anaconda.sh -b -p /opt/conda && \ 
	rm ~/anaconda.sh 

RUN TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \ 
	curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \ 
	dpkg -i tini.deb && \ 
	rm tini.deb && \ 
	apt-get clean

RUN apt-get update && apt-get install -y python3-pip
ENV PATH $PATH:/opt/conda/bin
ENV PYTHON_VERSION 3.6.3
ENV PYSPARK_PYTHON python3.6
ENV PYSPARK_DRIVER_PYTHON python3.6
ENV PYTHONPATH ${SPARK_HOME}/python/:${SPARK_HOME}/python/lib/py4j-0.10.4-src.zip:${PYTHONPATH}

# Packages for HDFS interaction
RUN pip install hdfs pywebhdfs







