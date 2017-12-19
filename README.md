# equoid-openshift

#Equoid Openshift Setup#

These instructions are for setting up Equoid on Openshift.

1. `oc login -u <username> <openshift url>`
1. `oc new-project equoid`
2. Browse to: \<openshift url\>:8443/console 
3. Add to project -> Browse catalog -> Red Hat JBoss A-MQ 6.3 (Ephemeral, no SSL) with options
    * MQ_PROTOCOL=amqp
    * MQ_QUEUES=salesq
    * MQ_TOPICS=salest
    * MQ_USERNAME=daikon
    * MQ_PASSWORD=daikon
3. Add to project -> Browse catalog -> PostgreSQL (Ephemeral) with options
    * POSTGRESQL_USER=daikon
    * POSTGRESQL_PASSWORD=daikon
    * POSTGRESQL_DATABASE=salesdb
4. Back to local bash shell, ``PODNAME=`oc get pods | grep postgresql | awk '{split($0,a," *"); print a[1]}'` ``
5. `oc rsh $PODNAME`
    1. `psql -c 'CREATE TABLE SALES (ITEMID TEXT NOT NULL, QUANTITY INTEGER NOT NULL);' -h postgresql salesdb daikon`
    2. `psql -c 'ALTER TABLE SALES ADD CONSTRAINT ITEMPK PRIMARY KEY (ITEMID);' -h postgresql salesdb daikon`  
    2. `exit`
6. `oc new-app --template=oshinko-pyspark-build-dc -p APPLICATION_NAME=equoid-data-handler -p GIT_URI=https://github.com/eldritchjs/equoid-data-handler -p GIT_REF=amqprcv -p APP_FILE=app.py -p SPARK_OPTIONS='--jars libs/spark-streaming-amqp_2.11-0.3.2-SNAPSHOT.jar'`
7. `oc expose svc/equoid-data-handler`
8. ``AMQPODNAME=`oc get pods | grep broker-amq | awk '{split($0,a," *"); print a[1]}'` ``
9. `oc port-forward $AMQPODNAME 5672 5672`
10. Run equoid-data-publisher per https://github.com/EldritchJS/equoid-data-publisher
11. Back to Openshift in your browser, Browse to equoid-data-handler
