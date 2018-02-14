#!/bin/bash
# Set some sensible defaults
export CORE_CONF_fs_defaultFS=${CORE_CONF_fs_defaultFS:-hdfs://`hostname -f`:8020}
function addProperty() {
  local path=$1
  local name=$2
  local value=$3
  local entry="<property><name>$name</name><value>${value}</value></property>"
  local escapedEntry=$(echo $entry | sed 's/\//\\\//g')
  sed -i "/<\/configuration>/ s/.*/${escapedEntry}\n&/" $path
}
function configure() {
    local path=$1
    local module=$2
    local envPrefix=$3
    local var
    local value
    echo "Configuring $module"
    for c in `printenv | perl -sne 'print "$1 " if m/^${envPrefix}_(.+?)=.*/' -- -envPrefix=$envPrefix`; do 
        name=`echo ${c} | perl -pe 's/___/-/g; s/__/_/g; s/_/./g'`
        var="${envPrefix}_${c}"
        value=${!var}
        echo " - Setting $name=$value"
        addProperty /etc/hadoop/$module-site.xml $name "$value"
    done
}
function configureHostResolver() {
    sed -i "/hosts:/ s/.*/hosts: $*/" /etc/nsswitch.conf
}
configure /etc/hadoop/core-site.xml core CORE_CONF
configure /etc/hadoop/hdfs-site.xml hdfs HDFS_CONF
configure /etc/hadoop/yarn-site.xml yarn YARN_CONF
configure /etc/hadoop/httpfs-site.xml httpfs HTTPFS_CONF
configure /etc/hadoop/kms-site.xml kms KMS_CONF
if [ "$MULTIHOMED_NETWORK" = "1" ]; then
    echo "Configuring for multihomed network"
    # HDFS
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.rpc-bind-host 0.0.0.0
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.servicerpc-bind-host 0.0.0.0
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.http-bind-host 0.0.0.0
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.https-bind-host 0.0.0.0
    addProperty /etc/hadoop/hdfs-site.xml dfs.client.use.datanode.hostname true
    addProperty /etc/hadoop/hdfs-site.xml dfs.datanode.use.datanode.hostname true
    # Avoid hostname check to allow datanode daemons join the namenode
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.datanode.registration.ip-hostname-check false
    # YARN
    addProperty /etc/hadoop/yarn-site.xml yarn.resourcemanager.bind-host 0.0.0.0
    addProperty /etc/hadoop/yarn-site.xml yarn.nodemanager.bind-host 0.0.0.0
    addProperty /etc/hadoop/yarn-site.xml yarn.nodemanager.bind-host 0.0.0.0
    addProperty /etc/hadoop/yarn-site.xml yarn.timeline-service.bind-host 0.0.0.0
    # MAPRED
    addProperty /etc/hadoop/mapred-site.xml yarn.nodemanager.bind-host 0.0.0.0
fi
if [ -n "$GANGLIA_HOST" ]; then
    mv /etc/hadoop/hadoop-metrics.properties /etc/hadoop/hadoop-metrics.properties.orig
    mv /etc/hadoop/hadoop-metrics2.properties /etc/hadoop/hadoop-metrics2.properties.orig
    for module in mapred jvm rpc ugi; do
        echo "$module.class=org.apache.hadoop.metrics.ganglia.GangliaContext31"
        echo "$module.period=10"
        echo "$module.servers=$GANGLIA_HOST:8649"
    done > /etc/hadoop/hadoop-metrics.properties
    for module in namenode datanode resourcemanager nodemanager mrappmaster jobhistoryserver; do
        echo "$module.sink.ganglia.class=org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31"
        echo "$module.sink.ganglia.period=10"
        echo "$module.sink.ganglia.supportsparse=true"
        echo "$module.sink.ganglia.slope=jvm.metrics.gcCount=zero,jvm.metrics.memHeapUsedM=both"
        echo "$module.sink.ganglia.dmax=jvm.metrics.threadsBlocked=70,jvm.metrics.memHeapUsedM=40"
        echo "$module.sink.ganglia.servers=$GANGLIA_HOST:8649"
    done > /etc/hadoop/hadoop-metrics2.properties
fi
case $HOST_RESOLVER in
    "")
        echo "No host resolver specified. Using distro default. (Specify HOST_RESOLVER to change)"
        ;;  
    files_only)
        echo "Configure host resolver to only use files"
        configureHostResolver files
        ;;
    dns_only)
        echo "Configure host resolver to only use dns"
        configureHostResolver dns
        ;;
    dns_files)
        echo "Configure host resolver to use in order dns, files"
        configureHostResolver dns files
        ;;
    files_dns)
        echo "Configure host resolver to use in order files, dns"
        configureHostResolver files dns
        ;;
    *)
        echo "Unrecognised network resolver configuration [${HOST_RESOLVER}]: allowed values are files_only, dns_only, dns_files, files_dns. Ignoring..."
        ;;        
esac
if [ -n "$HADOOP_CUSTOM_CONF_DIR" ]; then
    if [ -d "$HADOOP_CUSTOM_CONF_DIR" ]; then
        for f in `ls $HADOOP_CUSTOM_CONF_DIR/`; do
            echo "Applying custom Hadoop configuration file: $f"
            ln -sfn "$HADOOP_CUSTOM_CONF_DIR/$f" "/etc/hadoop/$f"
        done
    else
        echo >&2 "Hadoop custom configuration directory not found or not a directory. Ignoring: $HADOOP_CUSTOM_CONF_DIR"
    fi
fi
exec $@
