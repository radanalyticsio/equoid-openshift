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
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json

oc create -f https://radanalytics.io/resources.yaml

oc new-app --template=amq63-basic \
  -p MQ_PROTOCOL=amqp \
	-p MQ_QUEUES=salesq \
  -p MQ_USERNAME=daikon \
	-p MQ_PASSWORD=daikon \
  -p IMAGE_STREAM_NAMESPACE=`oc project -q`

oc create -f https://raw.githubusercontent.com/infinispan/infinispan-openshift-templates/master/templates/infinispan-ephemeral.json

oc new-app --template=infinispan-ephemeral \
	-l app=datagrid \
	-p APPLICATION_NAME=datagrid \
	-p NAMESPACE=`oc project -q` \
	-p APPLICATION_USER=daikon \
	-p APPLICATION_PASSWORD=daikon \
	-p MANAGEMENT_USER=daikon \
	-p MANAGEMENT_PASSWORD=daikon 

oc new-app oshinko-webui

