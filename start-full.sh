#!/bin/bash

PROJECT_NAME=equoid

if [ $# -gt 1 ];
then
	echo "Usage: $0 [project name]"
	exit
fi

if [ $# -gt 0 ];
then
	PROJECT_NAME=$1
fi

oc new-project $PROJECT_NAME
oc create -f  https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json

oc new-app --template=amq63-basic \
	-p MQ_PROTOCOL=amqp \
	-p MQ_QUEUES=salesq \
        -p MQ_USERNAME=daikon \
	-p MQ_PASSWORD=daikon \
        -p IMAGE_STREAM_NAMESPACE=$PROJECT_NAME	

oc create -f https://radanalytics.io/resources.yaml

oc create -f https://raw.githubusercontent.com/infinispan/infinispan-openshift-templates/master/templates/infinispan-ephemeral.json

oc new-app --template=infinispan-ephemeral \
	-l app=datagrid \
	-p APPLICATION_NAME=datagrid \
	-p NAMESPACE=$PROJECT_NAME \
	-p APPLICATION_USER=daikon \
	-p APPLICATION_PASSWORD=daikon \
	-p MANAGEMENT_USER=daikon \
	-p MANAGEMENT_PASSWORD=daikon 

oc new-app --template=oshinko-scala-spark-build-dc \
	-l app=handler \
	-p SBT_ARGS=assembly \
	-p OSHINKO_CLUSTER_NAME=sparky \
	-p APPLICATION_NAME=equoid-data-handler \
	-p GIT_URI=https://github.com/eldritchjs/equoid-data-handler \
	-p GIT_REF=ivupdate \
	-p APP_MAIN_CLASS=io.radanalytics.equoid.DataHandler \
	-e jdgHost=datagrid-hotrod \
	-e jdgPort=11222 \
	-p SPARK_OPTIONS='--driver-java-options=-Dvertx.cacheDirBase=/tmp'

oc new-app --allow-missing-imagestream-tags \
	-l app=publisher \
	--image-stream=$PROJECT_NAME/redhat-openjdk18-openshift:1.2 \
	https://github.com/eldritchjs/equoid-data-publisher 

oc new-app oshinko-webui

