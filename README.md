# Equoid Openshift Setup

### Automated Setup ####
To run the equoid system, be certain you have access to a cluster and are logged in, you then can use the `start-full.sh` script as follows: 

```bash
./start-full.sh [PROJECT_NAME]
```

for purposes of this document PROJECT_NAME will be equoid, which is also the default name if none is provided.

### Semi-Automated Setup with Template ###
A template is provided in `equoid-setup-list.yaml` for those wishing to use the Openshift web UI, those wanting to add equoid's components to their cluster's available components (i.e. in the Add to Project section) or those wishing to tweak parameters. The following steps should be taken:

1. Start the required components that are not contained within equoid:
```bash
./start-foundation.sh [PROJECT_NAME]
```
2. Import the template file `equoid-setup-list.yaml` via the Openshift web UI or the following command:
```bash
oc create -f equoid-setup-list.yaml
```
3. Add an equoid instance to your project via the Openshift web UI 

### Manual Setup ###
If interested in the system setup steps, the following instructions can be followed:

1. Make certain you have oc client in version `3.7` or higher:
```bash
oc version
# oc v3.7.0+7ed6862
```
2. (Local only) start the local cluster:
```bash
oc cluster up
```

3. Log in to your cluster. For this example we'll log in as developer:
```bash
oc login -u developer
```

4. Create a new project:
```bash
oc new-project equoid
```

5. Create the JBoss image streams needed for AMQ-P and publisher:
```bash
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/openjdk/openjdk18-image-stream.json
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-image-stream.json
```

6. Create the AMQ-P template:
```bash
oc create -n openshift -f \
  https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json
```

7. Instantiate the AMQ-P template:
```bash
oc new-app --template=amq63-basic \
  -p MQ_PROTOCOL=amqp \
  -p MQ_QUEUES=salesq \
  -p MQ_USERNAME=daikon \
  -p MQ_PASSWORD=daikon \
  -p IMAGE_STREAM_NAMESPACE=equoid  
```

8. Create radanalytics.io resources:
```bash
oc create -f https://radanalytics.io/resources.yaml
```

9. Create the Infinispan template:
```bash
oc create -f https://raw.githubusercontent.com/infinispan/infinispan-openshift-templates/master/templates/infinispan-ephemeral.json
```

10. Instantiate the Infinispan template:
```bash
oc new-app --template=infinispan-ephemeral \
  -l app=datagrid \
  -p APPLICATION_NAME=datagrid \
  -p NAMESPACE=equoid \
  -p APPLICATION_USER=daikon \
  -p APPLICATION_PASSWORD=daikon \
  -p MANAGEMENT_USER=daikon \
  -p MANAGEMENT_PASSWORD=daikon 
```

11. Create the data handler app (consumer of the events):
```bash
oc new-app --template=oshinko-scala-spark-build-dc \
  -l app=handler \
  -p SBT_ARGS=assembly \
  -p OSHINKO_CLUSTER_NAME=sparky \
  -p APPLICATION_NAME=equoid-data-handler \
  -p GIT_URI=https://github.com/eldritchjs/equoid-data-handler \
  -p APP_MAIN_CLASS=io.radanalytics.equoid.dataHandler \
  -p jdgHost=datagrid-hotrod \
  -p jdgPort=11222 \
  -p SPARK_OPTIONS='--driver-java-options=-Dvertx.cacheDirBase=/tmp'
```

12. Create the data publisher app (producer of the events):
```bash
oc new-app --allow-missing-imagestream-tags \
  -l app=publisher \
  --image-stream=equoid/redhat-openjdk18-openshift:1.3 \
  https://github.com/eldritchjs/equoid-data-publisher 
```

13. (Optional) create infinispan-dump app for periodic dumping of the contents of the Infinispan cache:
```bash
oc new-app --allow-missing-imagestream-tags \
  -l app=infinispan-dump \
  --image-stream=equoid/redhat-openjdk18.openshift:1.3 \
  https://github.com/eldritchjs/infinispan-dump
```


