#!/bin/bash
docker kill `docker ps -q` || true
oc cluster up
oc login -u system:admin
oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json
oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json
oc login -u developer

oc new-project equoid

oc new-app --template=amq63-basic \
  -l app=broker \
  -p MQ_PROTOCOL=amqp \
  -p MQ_QUEUES=salesq \
  -p MQ_TOPICS=salest \
  -p MQ_USERNAME=daikon \
  -p MQ_PASSWORD=daikon
  

oc create -f infinispan.json
oc create -f https://radanalytics.io/resources.yaml

sleep 5
AMQP_IP=`oc describe pod -l application=broker | grep IP | awk '{split($0,a,"\t*"); print a[2]}'`
echo broker IP: $AMQP_IP

oc new-app --template=oshinko-java-spark-build-dc \
  -l app=handler \
  -p OSHINKO_CLUSTER_NAME=sparky \
  -p APPLICATION_NAME=equoid-data-handler \
  -p GIT_URI=https://github.com/eldritchjs/equoid-data-handler \
  -p APP_MAIN_CLASS=io.radanalytics.equoid.dataHandler \
  -p APP_ARGS='broker-amq-amqp 5672 daikon daikon salesq datagrid-hotrod 11333 10 6 0.9' \
  -p APP_FILE=equoid-data-handler-1.0-SNAPSHOT.jar \
  -p SPARK_OPTIONS='--driver-java-options=-Dvertx.cacheDirBase=/tmp'

sleep 5

oc new-app -l app=publisher redhat-openjdk18-openshift:1.2~https://github.com/EldritchJS/equoid-data-publisher

