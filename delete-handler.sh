#!/bin/bash

[[ $# -lt 1 ]] || [ -z "${1##*[!0-9]*}" ] && echo "usage: ./delete-handler.sh <interval-in-seconds>" && exit

SECONDS=$1

oc delete all -l app=handler-$SECONDS
oc delete all -l oshinko-cluster=sparky-$SECONDS