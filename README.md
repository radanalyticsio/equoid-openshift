# equoid-openshift

#Equoid Openshift Setup#

These instructions are for setting up Equoid on Openshift.

1. `oc login -u system:admin <openshift address>:<openshift port>`
2. `oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json`
3. `oc logout`
4. `oc login -u <username> <openshift address>:<openshift port>`
5. `oc new-project equoid`
6. `oc new-app amq63-basic \
	-p APPLICATION_NAME=broker \
	-p MQ_PROTOCOL=amqp \
	-p MQ_QUEUES=salesq \
	-p MQ_USERNAME=daikon \
	-p MQ_PASSWORD=daikon`
7. `oc create -f infinispan.json`
8. ``AMQPODNAME=`oc get pods | grep broker-amq | awk '{split($0,a," *"); print a[1]}'` ``
9. `oc port-forward $AMQPODNAME 5672 5672`
10. Set up oshinko per https://radanalytics.io/get-started
11. Run equoid-data-publisher per https://github.com/EldritchJS/equoid-data-publisher
12. Run equoid-data-handler per https://github.com/EldritchJS/equoid-data-handler 
