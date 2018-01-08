# equoid-openshift

#Equoid Openshift Setup#

These instructions are for setting up Equoid on Openshift.

1. `oc login -u system:admin <openshift address>:<openshift port>`
1. `oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json`
1. `oc logout`
1. `oc login -u <username> <openshift address>:<openshift port>`
1. `oc new-project equoid`
1. `oc new-app amq63-basic \
	-p APPLICATION_NAME=broker \
	-p MQ_PROTOCOL=amqp \
	-p MQ_QUEUES=salesq \
	-p MQ_USERNAME=daikon \
	-p MQ_PASSWORD=daikon`
8. `oc create -f infinispan.json`
8. ``AMQPODNAME=`oc get pods | grep broker-amq | awk '{split($0,a," *"); print a[1]}'` ``
9. `oc port-forward $AMQPODNAME 5672 5672`
10. Run equoid-data-publisher per https://github.com/EldritchJS/equoid-data-publisher
11. TODO
