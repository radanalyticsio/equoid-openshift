# Equoid Openshift (local cluster) Setup

These instructions are for setting up Equoid on Openshift local cluster.
1. make sure you have oc client in version `3.7`
```bash
oc version
# oc v3.7.0+7ed6862
```
2. run the local cluster
```bash
oc cluster up
```

3. prepare image streams and some templates in the `openshift` namespace
```bash
oc login -u system:admin
```

```bash
# create image streams (needed by amq template)
oc create -n openshift -f \
  https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json
```

```bash
# create the amqp ephemeral template
oc create -n openshift -f \
  https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json
```

4. change the user to mere mortal again
```bash
oc login -u developer
```

5. create new project
```bash
oc new-project equoid
```

6. instantiate the amqp template
```bash 
oc new-app --template=amq63-basic \
	-p MQ_PROTOCOL=amqp \
	-p MQ_QUEUES=salesq \
	-p MQ_TOPICS=salest \
   	-p MQ_USERNAME=daikon\
	-p MQ_PASSWORD=daikon
```

7. instantiate the infinispan template
```bash
oc create -f infinispan.json
```

8. create radanalytics.io resources:
```bash
oc create -f https://radanalytics.io/resources.yaml
```

9. create the data handler app (consumer of the events)
```bash
oc new-app --template=oshinko-java-spark-build-dc \
	-p OSHINKO_CLUSTER_NAME=sparky \
	-p APPLICATION_NAME=equoid-data-handler \
	-p GIT_URI=https://github.com/eldritchjs/equoid-data-handler \
	-p APP_MAIN_CLASS=io.radanalytics.equoid.dataHandler \
	-p APP_ARGS='broker-amq-amqp 5672 daikon daikon salesq datagrid-hotrod 11333' \
	-p APP_FILE=equoid-data-handler-1.0-SNAPSHOT.jar \
	-p SPARK_OPTIONS='--driver-java-options=-Dvertx.cacheDirBase=/tmp'
```
9. get amqp pod ID from openshift 
```bash
AMQPODNAME=`oc get pods | grep broker-amq | awk '{split($0,a," *"); print a[1]}'` ``
```

10. forward your local machine's port to the amqp pod's port
```bash
oc port-forward $AMQPODNAME 5672 5672
```
11. Run equoid-data-publisher per https://github.com/EldritchJS/equoid-data-publisher
```bash
oc new-app redhat-openjdk18-openshift~https://github.com/EldritchJS/equoid-data-publisher \
	-e JAVA_MAIN_CLASS=io.radanalytics.equoid.dataPublisher
	-e ARTIFACT_COPY_ARGS='-r lib *.jar data'
	-e JAVA_APP_JAR=equoid-data-publisher-1.0-SNAPSHOT.jar \
	-e JAVA_ARGS='broker-amq-amqp 5672 daikon daikon salesq data/LiquorNames.txt'
```

12. (Optional) create cache checker for periodic key checking of \<KEY\_TO\_CHECK\> every five seconds for \<ITERATIONS\> times
```bash
oc new-app --template=oshinko-java-spark-build-dc \
	-p APPLICATION_NAME=equoid-check-cache \
	-p GIT_URI=https://github.com/eldritchjs/equoid-data-handler \
	-p APP_MAIN_CLASS=io.radanalytics.equoid.checkCache \
	-p APP_FILE=equoid-data-handler-1.0-SNAPSHOT.jar \
	-p APP_ARGS='datagrid-hotrod 11333 <KEY_TO_CHECK> <ITERATIONS>'
```
