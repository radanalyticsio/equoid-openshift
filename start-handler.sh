#!/bin/bash

[[ $# -lt 1 ]] || [ -z "${1##*[!0-9]*}" ] && echo "usage: ./start-handler.sh <interval-in-seconds>" && exit

SECONDS=$1
oc new-app --template=oshinko-scala-spark-build-dc \
    -l app=handler-$SECONDS \
    -p SBT_ARGS=assembly \
    -p OSHINKO_CLUSTER_NAME=sparky-$SECONDS \
    -p APPLICATION_NAME=equoid-data-handler-$SECONDS \
    -p GIT_URI=https://github.com/eldritchjs/equoid-data-handler \
    -p GIT_REF=ivupdate \
    -p APP_MAIN_CLASS=io.radanalytics.equoid.DataHandler \
    -e JDG_HOST=datagrid-hotrod \
    -e JDG_PORT=11222 \
    -e WINDOW_SECONDS=$SECONDS \
    -e SLIDE_SECONDS=$SECONDS \
    -p SPARK_OPTIONS='--driver-java-options=-Dvertx.cacheDirBase=/tmp'