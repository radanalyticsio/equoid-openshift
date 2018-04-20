#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
METRICS="${METRICS:-"0"}"

# Prometheus and Grafana
if [ "$METRICS" = "1" ] ; then
  oc process -f $DIR/monitoring/metrics.yml | oc apply -f -
fi

# Keycloak SSO
oc secrets new kc-realm jhipster-realm.json=$DIR/keycloak/realm-config/jhipster-realm.json
oc secrets new kc-users jhipster-users-0.json=$DIR/keycloak/realm-config/jhipster-users-0.json
oc process -f $DIR/keycloak/keycloak.yml | oc apply -f -

# Finally, deploy the Equoid app
oc process -f $DIR/equoid/equoid-deployment.yml | oc apply -f -

KC_ROUTE=`oc get routes -l app=equoid-keycloak --no-headers | awk '{print $2}'`
if [[ $KC_ROUTE = *"127.0.0."* ]]; then
  echo "Running on local cluster => no need to modify the keycloak url"
else
  echo "Equoid app will be using this keycloak instance: http://$KC_ROUTE"
  oc env dc/equoid KEYCLOAK_URL=$KC_ROUTE
fi
