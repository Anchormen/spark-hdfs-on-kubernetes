#!/bin/sh

. /start-common.sh

/opt/spark/sbin/start-slave.sh spark://spark-master:7077 -c ${SPARK_WORKER_REQUESTS_CPU} -m ${SPARK_WORKER_REQUESTS_MEMORY}
