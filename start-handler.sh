#!/bin/bash

[[ $# -lt 1 ]] || [ -z "${1##*[!0-9]*}" ] && echo "usage: ./start-handler.sh <interval-in-seconds>" && exit

SECONDS=$1
OPMODE=$2
oc new-app --template=oshinko-scala-spark-build-dc \
    -l app=handler-$SECONDS-$OPMODE \
    -p SBT_ARGS=assembly \
    -p APPLICATION_NAME=equoid-data-handler-$SECONDS-$OPMODE \
    -p GIT_URI=https://github.com/eldritchjs/equoid-data-handler \
    -p GIT_REF=DataMod \
    -p APP_MAIN_CLASS=io.radanalytics.equoid.DataHandler \
    -e JDG_HOST=datagrid-hotrod \
    -e JDG_PORT=11222 \
    -e WINDOW_SECONDS=$SECONDS \
    -e SLIDE_SECONDS=$SECONDS \
    -e BATCH_SECONDS=$SECONDS \
    -e OP_MODE=$OPMODE \ 
    -p SPARK_OPTIONS='--driver-java-options=-Dvertx.cacheDirBase=/tmp'
