#!/usr/bin/env bash

# Start the cron service for DSpace's scheduled maintenance tasks
# See: /etc/cron.d/dspace-maintenance-tasks
service cron start

POSTGRES_DB_HOST=${POSTGRES_DB_HOST:-$POSTGRES_PORT_5432_TCP_ADDR}
POSTGRES_DB_PORT=${POSTGRES_DB_PORT:-$POSTGRES_PORT_5432_TCP_PORT}
POSTGRES_DB_PORT=${POSTGRES_DB_PORT:-5432}

# Create PostgreSQL user and database schema
if [ -n $POSTGRES_DB_HOST -a -n $POSTGRES_DB_PORT ]; then
    # Wait for PostgreSQL and then call `setup-postgres.sh` script
    # See: https://docs.docker.com/compose/startup-order/
    wait-for-postgres.sh $POSTGRES_DB_HOST setup-postgres.sh
fi

# Remove unused webapps
# see https://wiki.duraspace.org/display/DSDOC5x/Performance+Tuning+DSpace
if [ -n "$DSPACE_WEBAPPS" ]; then
    webapps=($(ls $CATALINA_HOME/webapps | tr -d '/'))
    webapps_to_keep=($(echo "$DSPACE_WEBAPPS solr"))
    for element in ${webapps_to_keep[@]}; do
      webapps=(${webapps[@]/$element})
    done
    for webapp in ${webapps[@]}; do
      rm -rf $CATALINA_HOME/webapps/$webapp
    done
fi

# Start Tomcat (with full path to catalina.sh, because su resets our $PATH)
exec su - dspace -c "$CATALINA_HOME/bin/catalina.sh run"
