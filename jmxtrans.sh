#!/bin/sh -u

######################################
## Configuration
######################################
HEAP_SIZE=${HEAP_SIZE:-"512"}
## JMX Configuration (for remote system)
TARGET_JMX_HOST=${TARGET_JMX_HOST:-"localhost"}
TARGET_JMX_PORT=${TARGET_JMX_PORT:-"8004"}
TARGET_HOSTNAME=${TARGET_HOSTNAME:-$TARGET_JMX_HOST}
TARGET_NODE_ID=${TARGET_NODE_ID:-"NC"}
TARGET_JMX_USER=${TARGET_JMX_USER:-"nobody"}
TARGET_JMX_PASSWORD=${TARGET_JMX_PASSWORD:-"nothing"}
## Influxdb Configuration
TARGET_INFLUXDB_URL=${TARGET_INFLUXDB_URL:-"http://localhost:8086"}
TARGET_INFLUXDB_DATABASE=${TARGET_INFLUXDB_DATABASE:-"exo"}
TARGET_INFLUXDB_USERNAME=${TARGET_INFLUXDB_USERNAME:-"nobody"}
TARGET_INFLUXDB_PASSWORD=${TARGET_INFLUXDB_PASSWORD:-"nothing"}
TARGET_INFLUXDB_CREATE_DB=${TARGET_INFLUXDB_CREATE_DB:-"true"}
TARGET_INFLUXDB_RETENTION_POLICY=${TARGET_INFLUXDB_RETENTION_POLICY:-"autogen"}
# JMXTrans Configuration
JMXTRANS_POOLING_FREQUENCY=${JMXTRANS_POOLING_FREQUENCY:-"30"} # the frequency is in seconds
JMXTRANS_LOG_LEVEL=${JMXTRANS_LOG_LEVEL:-"WARN"} # [DEBUG|INFO|WARN|ERROR|FATAL] (default: WARN)

######################################
## /!\ DON'T CHANGE ANYTHING BELOW /!\
######################################

JMXTRANS_OPTS="${JMXTRANS_OPTS:-} -Duser.language=en -Duser.region=EN" # Always use the same Locale (en_EN) is a good practice to avoid localization problems between different servers
JMXTRANS_OPTS="${JMXTRANS_OPTS:-} --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.lang.invoke=ALL-UNNAMED --add-opens java.management/javax.management=ALL-UNNAMED" # Suppress the warning : Illegal reflective access
JMXTRANS_OPTS="${JMXTRANS_OPTS} -DTARGET_JMX_HOST=${TARGET_JMX_HOST} -DTARGET_JMX_PORT=${TARGET_JMX_PORT}"
JMXTRANS_OPTS="${JMXTRANS_OPTS} -DTARGET_JMX_USER=${TARGET_JMX_USER} -DTARGET_JMX_PASSWORD=${TARGET_JMX_PASSWORD}"
JMXTRANS_OPTS="${JMXTRANS_OPTS} -DTARGET_INFLUXDB_URL=${TARGET_INFLUXDB_URL} -DTARGET_INFLUXDB_DATABASE=${TARGET_INFLUXDB_DATABASE}"
JMXTRANS_OPTS="${JMXTRANS_OPTS} -DTARGET_INFLUXDB_USERNAME=${TARGET_INFLUXDB_USERNAME} -DTARGET_INFLUXDB_PASSWORD=${TARGET_INFLUXDB_PASSWORD}"
JMXTRANS_OPTS="${JMXTRANS_OPTS} -DTARGET_INFLUXDB_CREATE_DB=${TARGET_INFLUXDB_CREATE_DB} -DTARGET_INFLUXDB_RETENTION_POLICY=${TARGET_INFLUXDB_RETENTION_POLICY}"
JMXTRANS_OPTS="${JMXTRANS_OPTS} -DTARGET_HOSTNAME=${TARGET_HOSTNAME} -DTARGET_NODE_ID=${TARGET_NODE_ID}"
JMXTRANS_OPTS="${JMXTRANS_OPTS} -DJMXTRANS_LOG_LEVEL=${JMXTRANS_LOG_LEVEL} -Dlogback.configurationFile=file://${JMXTRANS_APP_DIR}/logback.xml"

SECONDS_BETWEEN_RUNS=${JMXTRANS_POOLING_FREQUENCY}
CONTINUE_ON_ERROR=false

EXEC="-jar ${JMXTRANS_APP_DIR}/${JMXTRANS_JAR_FILE} -e -j ${JMXTRANS_JSON_DIR} -s ${SECONDS_BETWEEN_RUNS} -c ${CONTINUE_ON_ERROR} ${ADDITIONAL_JARS_OPTS:-}"
GC_OPTS="-Xms${HEAP_SIZE}m -Xmx${HEAP_SIZE}m"
#MONITOR_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.ssl=false \
#              -Dcom.sun.management.jmxremote.authenticate=false \
#              -Dcom.sun.management.jmxremote.port=9999 \
#              -Dcom.sun.management.jmxremote.rmi.port=9999 \
#              -Djava.rmi.server.hostname=${TARGET_JMX_HOST}"

if [ "$1" != "bash" -a "$1" != "sh" ]; then
    echo "$1"
    echo "$@"
    echo "TARGET_JMX_HOST                   : ${TARGET_JMX_HOST}"
    echo "TARGET_JMX_PORT                   : ${TARGET_JMX_PORT}"
    echo "TARGET_HOSTNAME                   : ${TARGET_HOSTNAME}"
    echo "TARGET_NODE_ID                    : ${TARGET_NODE_ID}"
    echo "TARGET_JMX_USER                   : ${TARGET_JMX_USER}"
    echo "TARGET_INFLUXDB_URL               : ${TARGET_INFLUXDB_URL}"
    echo "TARGET_INFLUXDB_DATABASE          : ${TARGET_INFLUXDB_DATABASE}"
    echo "TARGET_INFLUXDB_USERNAME          : ${TARGET_INFLUXDB_USERNAME}"
    echo "TARGET_INFLUXDB_CREATE_DB         : ${TARGET_INFLUXDB_CREATE_DB}"
    echo "TARGET_INFLUXDB_RETENTION_POLICY  : ${TARGET_INFLUXDB_RETENTION_POLICY}"
    echo "SECONDS_BETWEEN_RUNS              : ${SECONDS_BETWEEN_RUNS}"

    gosu nobody:nogroup java -server ${JAVA_OPTS:-} ${JMXTRANS_OPTS} ${GC_OPTS} ${MONITOR_OPTS:-} ${EXEC}
else
    "$@"
fi

