#!/bin/sh
# Healthy when the jmxtrans JVM is running, the InfluxDB server answers its
# /ping endpoint and the target JMX port accepts connections.
set -eu

pgrep -f jmxtrans-all.jar >/dev/null || exit 1
curl --fail --silent --show-error --max-time 5 "${TARGET_INFLUXDB_URL:-http://localhost:8086}/ping" >/dev/null || exit 1
nc -z -w 2 "${TARGET_JMX_HOST:-localhost}" "${TARGET_JMX_PORT:-8004}" || exit 1
