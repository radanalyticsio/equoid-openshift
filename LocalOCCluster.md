# equoid-openshift
# Equoid Openshift (local cluster) Setup

These instructions are for setting up Equoid on Openshift local cluster.
1. make sure you have oc client in version `3.7`
```bash
oc version
# oc v3.7.0+7ed6862
```
2. run the local cluster
```bash
oc cluster up
```

3. prepare image streams and some templates in the `openshift` namespace
```bash
oc login -u system:admin
```

```bash
# create image streams (needed by amq template)
oc create -n openshift -f \
  https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json
```

```bash
# create the amqp ephemeral template
oc create -n openshift -f \
  https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq63-basic.json
```

```bash
# create the mysql ephemeral template
oc create -n openshift -f \
  https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/postgresql-ephemeral-template.json
```

4. change the user to mere mortal again
```bash
oc login -u developer
```

5. create new project
```bash
oc new-project equoid
```

6. instantiate amqp the template
```bash 
oc new-app --template=amq63-basic -p MQ_PROTOCOL=amqp -p MQ_QUEUES=salesq -p MQ_TOPICS=salest \
   -p MQ_USERNAME=daikon -p MQ_PASSWORD=daikon
```

7. instantiate the postgresql template
```bash
oc new-app --template=postgresql-ephemeral -p POSTGRESQL_USER=daikon -p POSTGRESQL_PASSWORD=daikon -p POSTGRESQL_DATABASE=salesdb
```

8. Find the pod name with the DB:
```
PODNAME=`oc get pods | grep postgresql | awk '{split($0,a," *"); print a[1]}'`
```
9. and create simple schema in it: `oc rsh $PODNAME`
    1. `psql -U daikon -d salesdb -c 'CREATE TABLE SALES (ITEMID TEXT NOT NULL, QUANTITY INTEGER NOT NULL);'`
    1. `psql -U daikon -d salesdb -c 'ALTER TABLE SALES ADD CONSTRAINT ITEMPK PRIMARY KEY (ITEMID);'`  
    1. `exit`
10. create radanalytics.io resources:
```bash
oc create -f https://radanalytics.io/resources.yaml
```
11. create the data handler app (consumer of the events)
```bash
oc new-app --template=oshinko-pyspark-build-dc -p APPLICATION_NAME=equoid-data-handler -p GIT_URI=https://github.com/eldritchjs/equoid-data-handler -p GIT_REF=amqprcv -p APP_FILE=app.py -p SPARK_OPTIONS='--jars libs/spark-streaming-amqp_2.11-0.3.1.jar'
```
12. `oc expose svc/equoid-data-handler`
8. ``AMQPODNAME=`oc get pods | grep broker-amq | awk '{split($0,a," *"); print a[1]}'` ``
9. `oc port-forward $AMQPODNAME 5672 5672`
10. Run equoid-data-publisher per https://github.com/EldritchJS/equoid-data-publisher
11. Back to Openshift in your browser, Browse to equoid-data-handler
