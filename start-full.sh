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

oc new-project $PROJECT_NAME || oc project $PROJECT_NAME

oc create -f https://raw.githubusercontent.com/radanalyticsio/equoid-openshift/master/openjdk18-image-stream.json
oc create -f https://radanalytics.io/resources.yaml
oc create -f https://raw.githubusercontent.com/infinispan/infinispan-openshift-templates/master/templates/infinispan-ephemeral.json

oc create -f https://raw.githubusercontent.com/radanalyticsio/equoid-openshift/master/artemis-rc.yaml

oc new-app --template=infinispan-ephemeral \
    -l app=datagrid \
    -p APPLICATION_NAME=datagrid \
    -p NAMESPACE=`oc project -q` \
    -p APPLICATION_USER=daikon \
    -p APPLICATION_PASSWORD=daikon \
    -p MANAGEMENT_USER=daikon \
    -p MANAGEMENT_PASSWORD=daikon

oc new-app --template=oshinko-scala-spark-build-dc \
    -l app=handler-20-linear \
    -p SBT_ARGS=assembly \
    -p APPLICATION_NAME=equoid-data-handler-20-linear \
    -p GIT_URI=https://github.com/eldritchjs/equoid-data-handler-1 \
    -p GIT_REF=artemis \
    -p APP_MAIN_CLASS=io.radanalytics.equoid.DataHandler \
    -e JDG_HOST=datagrid-hotrod \
    -e JDG_PORT=11222 \
    -e WINDOW_SECONDS=20 \
    -e SLIDE_SECONDS=20 \
    -e BATCH_SECONDS=20 \
    -e OP_MODE=linear \
    -p SPARK_OPTIONS='--driver-java-options=-Dvertx.cacheDirBase=/tmp'

echo "Waiting for the imagestreamtag redhat-openjdk18-openshift:1.3"

until oc get imagestreamtag/redhat-openjdk18-openshift:1.3 &> /dev/null ; do
  printf "$(tput setaf 6)▮$(tput sgr0)"
  sleep 1
  oc create -f https://raw.githubusercontent.com/radanalyticsio/equoid-openshift/master/openjdk18-image-stream.json
done

oc new-app \
    -l app=publisher \
    -e OP_MODE=linear \
    -e DATA_URL_PRIMARY=https://raw.githubusercontent.com/radanalyticsio/equoid-data-publisher/master/data/StockCodesLinear.txt \
    --image-stream=`oc project -q`/redhat-openjdk18-openshift:1.3 \
    https://github.com/eldritchjs/equoid-data-publisher#artemis 

# web-ui
BASE_URL="https://raw.githubusercontent.com/radanalyticsio/equoid-ui/master/ocp/"
curl -sSL $BASE_URL/ocp-apply.sh | \
    BASE_URL="$BASE_URL" \
    KC_REALM_PATH="web-ui/keycloak/realm-config" \
    bash -s stable

oc policy add-role-to-user edit system:serviceaccount:$PROJECT_NAME:default
