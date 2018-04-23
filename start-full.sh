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
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/openjdk/openjdk18-image-stream.json
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-image-stream.json
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json

oc new-app --template=amq63-basic \
    -l app=amqp \
    -p MQ_PROTOCOL=amqp \
    -p MQ_QUEUES=salesq \
    -p MQ_USERNAME=daikon \
    -p MQ_PASSWORD=daikon \
    -p IMAGE_STREAM_NAMESPACE=`oc project -q`

oc create -f https://radanalytics.io/resources.yaml

oc create -f https://raw.githubusercontent.com/infinispan/infinispan-openshift-templates/master/templates/infinispan-ephemeral.json

oc new-app --template=infinispan-ephemeral \
    -l app=datagrid \
    -p APPLICATION_NAME=datagrid \
    -p NAMESPACE=`oc project -q` \
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
    -e JDG_HOST=datagrid-hotrod \
    -e JDG_PORT=11222 \
    -p SPARK_OPTIONS='--driver-java-options=-Dvertx.cacheDirBase=/tmp'


echo "Waiting for the imagestreamtag redhat-openjdk18-openshift:1.3"
until oc get imagestreamtag/redhat-openjdk18-openshift:1.3 &> /dev/null ; do
  printf "$(tput setaf 6)▮$(tput sgr0)"
  sleep 1
done

oc new-app \
    -l app=publisher \
    --image-stream=`oc project -q`/redhat-openjdk18-openshift:1.3 \
    https://github.com/eldritchjs/equoid-data-publisher

# web-ui
BASE_URL="https://raw.githubusercontent.com/Jiri-Kremser/equoid-ui/master/ocp/"
curl -sSL $BASE_URL/ocp-apply.sh | \
    BASE_URL="$BASE_URL" \
    KC_REALM_PATH="web-ui/keycloak/realm-config" \
    bash -s stable
