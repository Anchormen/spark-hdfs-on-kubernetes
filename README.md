# Affordable automatic deployment of Spark and HDFS with Kubernetes and Gitlab CI/CD

# Summary

Running an application on Spark with external dependencies, such as R and python packages, requires the installation of 
these dependencies on all the workers. To automate this tedious process, a continuous deployment workflow has been developed 
using Gitlab CI/CD. This workflow consists of: (i) Building the HDFS and Spark docker images with the required dependencies 
for workers and the master (Python and R), (ii) deploying the images on a Kubernetes cluster. For this, we used an affordable 
cluster made of mini PCs. Additionally, we will demonstrate that this cluster is fully operational. The Spark cluster is 
accessible using Spark UI, Zeppelin and R Studio. Moreover, HDFS is fully integrated together with Kubernetes. 
Source code for both the custom Docker images and the Kubernetes objects definitions can be found [here](https://hub.docker.com/r/angelsevillacamins) and [here](https://github.com/Anchormen/spark-hdfs-on-kubernetes) respectively.
See [here](https://anchormen.nl/blogs/) the complete blog post.

# Index
1. Gitlab auto-deployment with Kubernetes
2. Deploying the Spark server
3. Zeppelin and Spark 
4. Zeppelin and HDFS
5. Running parallelized R code with RStudio
6. PySpark using the command line in the master node

## 1.Gitlab auto-deployment with Kubernetes

### Configuring Kubernetes cluster

1. Check the connection with the Kubernetes server with:
```
kubectl get nodes
```
2. Create namespace with the same name of the repository as [here](https://Kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/)
3. Check and modify RBAC permissions as [here](https://Kubernetes.io/docs/admin/authorization/rbac/#default-roles-and-role-bindings)
4. Get a token and a certificate from an account with enough privileges. They should look like these:
    - CA Certificate
```
-----BEGIN CERTIFICATE-----
MIICyDCCAbCgAwIBAgIBADANBgkqhiiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
cm5ldGVzMB4XDTE3MTAzMDE1Mzc1M1oXDTI3MTAyODE1Mzc1M1owFTETMBEGA1UE
AxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANGF
iAFsP+J0nMZqpztdNOZnDqpOhTxxYQzdqTsa2aW8pQLn3lStW66ngwZjxcWvPVda
OganYnvmX4tk69fqRZP+nXSaIo82HWDCTGZ1HmdIueDT1xpoqlVlQUOtzmjRc39t
MgYw7wqX12zL8+pTfLL/409xVCUnK2Vg+sWB99JuUeJFSAeFBoxSAwqt8GgOVaR0
YAStjWp7MjOLE/IgFzd/SSepef51qzH2akb7UVow3zHhw83rNlC9U/0toXacv2T9
IcptsHLWU7+kv8GrsnhDsC05Ccs8ZR9lY6QHli1MLDmFQATvlpIlFFCc6aDcMODu
Ct7L5qYNQ3KMkUdmv1kCAwEAAaMjMCEwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB
/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAJdE76XwjxvHqrvw13JY+GTtrsvQ
uPjy4ApaAnKwlkqq1TLQGoW4R3rMiIZEVW0+QnYjXvplXgpiIpilem16f35r7lu9
rLoj6D7Pfc11aKzDkpYcV8DsbPh/IXpoY9olFMzEDUglm3Zn3ggJikxbFmuQR+Uo
UeUykfUavV4N40pCAVbzNdyf5yWZ0S4jtKoEyGDAHsBG4uAU0QVqmU8JWtic2dvu
M8LSn+7iVuv/zKYGK9KQ4Mvgj+jiNt0oYm6nJu3vzSO7Hjyr+seOYpJcIykCgOrG
juncJMyuPkBi4kskaKGfse6HA9Ve0Qk5fO0gkVvJBk6Jf4MvMSX5ijV8K7c=
-----END CERTIFICATE-----
```
    - Token (one line)
```
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3Nl
cnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3
BhY2UiOiKrdWJlcm5ldGVzLXRyaWdnZXItbW9kZWxzIiwia3ViZXJuZXRlcy5pby9z
ZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRlZmF1bHQtdG9rZW4tNnhkazYiLC
JrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lI
joiZGVmYXVsdCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1h
Y2NvdW50LnVpZCI6ImNiMjFkMjVkLWM0NjMtMTFlNy1hZjBlLWI4YWVlZDcyYzhhZSI
sInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLXRyaWdnZXItbW
9kZWxzOmRlZmF1bHQifQ.ea4lZ31or3dUXYGqfR7vZzqIevVaCebX80_9CjAzq8qX0f
nlvVZsfaBsRQATB-6PkYs2FhzHc9yII36LlYM__NeVQF6_FHxQfV8cMBixqUX_pG22J
PWo2hQWLNgYdKDQ4fpMihIR-2k6OaeIELD7inyMrH2p0RbDkpP64jo2fGeFe-nCeugx
97Owonu8YiI4uL1c0VS880p-1P9xfkOjgulRDUYsuFGwpT4INrHcarySX2VKnpdsAP4
M5hmfK7DhXn6fYifI8HOtTzpyrry7qOp10KlEYKaA8rJg_lwRrd7XeqXfYeYLONHcS-
K4Hqw7Kw3lTr3hFZvJa0YKuAOGUg
```

### Configuring Gitlab server 

Steps to add Kubernetes and auto-deployment to a gitlab repository:

1. Create a new repository (same name as the namespace previously generated). 
2. Enable Auto DevOps in Settings > CI/CD > General pipelines settings.
3. Go to Settings > CI/CD > Secret variables and add these variables:
    - **DOCKER_REGISTRY_USER** with the user of a Dockerhub account.
    - **DOCKER_REGISTRY_PASSWORD** with the password of a Dockerhub account.
    - **KUBE_CA_PEM** with the certificate obtained before.
    - **KUBE_TOKEN** with the token obtained before.
    - **RSTUDIO_PASSWORD** with a password to login Rstudio server.
    - **RSTUDIO_USER** with a user to login Rstudio server.
    - **ZEPPELIN_PASSWORD** with a password to login Zeppelin.
    - **ZEPPELIN_USER** with a user to login Zeppelin.
4. A gitlab runner should be available, look [here](https://docs.gitlab.com/runner/) how to set up one.

## 2.Deploying the Spark server

Go to CI/CD and press RUN PIPELINE or push changes to the repository.

After it is finished:
- For the master's web UI, go to [http://IP-nuc01:8080/](http://IP-nuc01:8080/)
- For the RStudio UI, go to [http://IP-nuc01:8787/](http://IP-nuc01:8787/)
- For the Zeppelin UI, go to [http://IP-nuc01:8181/](http://IP-nuc01:8181/)
- For the HDFS UI, run:
    ```
    export CI_PROJECT_NAME=<insert-namespace-name-here>
    kubectl port-forward hdfs-namenode-0 50070:50070 --namespace=${CI_PROJECT_NAME}
    ```
    and go to [http://locahost:50070/](http://localhost:50070/)

## 3.Zeppelin and Spark
Go to [http://IP-nuc01:8181/](http://IP-nuc01:8181/)

### PySpark in Zeppelin
```
%pyspark
textFile = spark.read.text("/opt/spark-2.2.0-bin-hadoop2.7/python/README.md")
from pyspark.sql.functions import *
textFile.select(size(split(textFile.value, "\s+")).name("numWords")).agg(max(col("numWords"))).collect()
```

### SparkR in Zeppelin
```
%spark.r
library(forecast)
# Data generation
data <- lapply(1:6, function(x) USAccDeaths)
str(data)
```
```
%spark.r
forecast_models <- function(ts_data) {
	library(forecast)
	ts_data %>% tbats %>% forecast(h=36)
}
```
```
%spark.r
system.time({
	spark.lapply(data, forecast_models)
})
```
Scale server in command line or Kubernetes UI
```
export CI_PROJECT_NAME=<insert-namespace-name-here>
kubectl scale --replicas=3 statefulset/spark-worker --namespace=${CI_PROJECT_NAME}
```
Then, run again:
```
%spark.r
system.time({
	spark.lapply(data, forecast_models)
})
```

### Variables and data frames can be shared among R, Scala and Python
```
%pyspark
# Export variable from Pyspark
z.put("pythonVariable", 66)
```

```
%spark.r
# Export data frame from SparkR
library(forecast)
data <- USAccDeaths
forecast_models <- function(ts_data) {
	library(forecast)
	ts_data %>% tbats %>% forecast(h=36)
}
sparkR_df <- as.DataFrame(as.data.frame(spark.lapply(data, forecast_models)[[1]]))
str(sparkR_df)
createOrReplaceTempView(sparkR_df, "sparkR_df")
```

```
%spark
// Export variable from spark (scala)
z.put("scalaVariable", "Hello, world Scala")
// Import variable from pyspark session into spark (scala)
z.get("pythonVariable")
// Import data frame from SparkR session into spark (scala)
val sqlDF = spark.sql("SELECT * FROM sparkR_df")
sqlDF.show()
```

```
%spark.r
# Import variables from scala and pyspark into SparkR session
z.get("scalaVariable")
z.get("pythonVariable")
```

```
%pyspark
# Import variables from scala and a data frame from SparkR into Pyspark session
print(z.get("scalaVariable"))
sqlDF = spark.sql("SELECT * FROM sparkR_df")
sqlDF.show()
```

## 4.Zeppelin and HDFS
Go to Zeppelin [http://IP-nuc01:8181/](http://IP-nuc01:8181/)

To use the pre-built Zeppelin interpreter for HDFS, run:
```
%file
ls /
```
With Pyspark, run the following lines as an example:
```
%pyspark
# Generate a simple spark dataframe
data = [('First', 1), ('Second', 2), ('Third', 3), ('Fourth', 4), ('Fifth', 5)]
df = sqlContext.createDataFrame(data)
df.show()
```
Write a data frame to parquet in HDFS
```
%pyspark
# Write to parquet in HDFS
df.write.parquet("hdfs://hdfs-namenode-0.hdfs-namenode.<insert-namespace-name-here>.svc.cluster.local/test/mydf", mode="overwrite")
```
Read the previous data frame
```
%pyspark
# Read the previous data frame
df_parquet = spark.read.load("hdfs://hdfs-namenode-0.hdfs-namenode.<insert-namespace-name-here>.svc.cluster.local/test/mydf")
df_parquet.show()
```
Interact with HDFS using pyspark and the WebHDFS REST API
- pywebhdfs package

```
%pyspark
# Interact with HDFS using pyspark and the WebHDFS REST API
# pywebhdfs package (Not included in Anaconda)
import json
from pprint import pprint
from pywebhdfs.webhdfs import PyWebHdfsClient

hdfs = PyWebHdfsClient(host='hdfs-namenode-0.hdfs-namenode.<insert-namespace-name-here>.svc.cluster.local',port='50070') 

data = hdfs.list_dir("/")
file_statuses = data["FileStatuses"]

for item in file_statuses["FileStatus"]:
    print (item["pathSuffix"])  
```

- hdfs package

```
%pyspark
# Interact with HDFS using pyspark and the WebHDFS REST API
# hdfs package (Not included in Anaconda)
from hdfs import InsecureClient
client = InsecureClient('http://hdfs-namenode-0.hdfs-namenode.<insert-namespace-name-here>.svc.cluster.local:50070')
fnames = client.list('/')
print(fnames)
```

## 5.Running parallelized R code with RStudio
Go to the RStudio UI [http://IP-nuc01:8787/](http://IP-nuc01:8787/) and run the following:
```
library(forecast)
# Data generation
data <- lapply(1:6, function(x) taylor)

forecast_models <- function(ts_data) {
	library(forecast)
	ts_data %>% tbats %>% forecast(h=36)
}

# Without parallelization
system.time({lapply(data, forecast_models)})
#	user   system  elapsed 
#	548.168    1.040 1372.809
 
# With parallelization 3 workers each 1 cpu
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
sparkR.session(master=Sys.getenv("MASTER"), sparkConfig = list(
    spark.driver.cores = Sys.getenv("SPARK_DRIVER_CORES"),
    spark.driver.memory = Sys.getenv("SPARK_DRIVER_MEMORY"),
    spark.driver.maxResultSize = Sys.getenv("SPARK_DRIVER_MAXRESULTSIZE"),
    # Uncomment the following line if SPARK_CORES_MAX is defined
    # spark.cores.max = Sys.getenv("SPARK_CORES_MAX"),
    spark.executor.cores = Sys.getenv("SPARK_EXECUTOR_CORES"),
    spark.executor.memory = Sys.getenv("SPARK_EXECUTOR_MEMORY")))
system.time({
	spark.lapply(data, forecast_models)
})
	sparkR.session.stop()
#   user  system elapsed                                                         
#  1.092   1.124 920.238  
```
Scale server in the command line (6 workers each 1 cpu)
```
export CI_PROJECT_NAME=<insert-namespace-name-here>
kubectl scale --replicas=6 statefulset/spark-worker --namespace=${CI_PROJECT_NAME}
```
Then, run again:
```
system.time({
	spark.lapply(data, forecast_models)
})
#    user  system elapsed                                                         
#	0.904   0.340 609.981
sparkR.session.stop()
```

## 6.PySpark using the command line in the master node
```
export CI_PROJECT_NAME=<insert-namespace-name-here>
kubectl exec -it spark-master-0 /bin/bash --namespace=${CI_PROJECT_NAME}
pyspark
textFile = spark.read.text("/opt/spark-2.2.0-bin-hadoop2.7/python/README.md")
from pyspark.sql.functions import *
textFile.select(size(split(textFile.value, "\s+")).name("numWords")).agg(max(col("numWords"))).collect()
```

