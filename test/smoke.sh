#!/bin/sh
# Smoke test: run the image against a real JMX endpoint and a real InfluxDB and
# check that metrics land in the database and that the healthcheck passes.
# The JMX target is a second jmxtrans container with remote JMX enabled.
# Usage: test/smoke.sh [image]   (default: exoplatform/jmxtrans:smoke)
set -eu

IMAGE=${1:-exoplatform/jmxtrans:smoke}
NET=jmxtrans-smoke-$$
cleanup() {
    docker rm -f "$NET-influx" "$NET-target" "$NET-jmxtrans" >/dev/null 2>&1 || true
    docker network rm "$NET" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker network create "$NET" >/dev/null
docker run -d --name "$NET-influx" --network "$NET" influxdb:1.8-alpine >/dev/null

docker run -d --name "$NET-target" --network "$NET" \
    -e MONITOR_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.ssl=false \
-Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=9999 \
-Dcom.sun.management.jmxremote.rmi.port=9999 -Djava.rmi.server.hostname=$NET-target" \
    "$IMAGE" >/dev/null

docker run -d --name "$NET-jmxtrans" --network "$NET" \
    -e TARGET_JMX_HOST="$NET-target" -e TARGET_JMX_PORT=9999 \
    -e TARGET_INFLUXDB_URL="http://$NET-influx:8086" \
    -e JMXTRANS_POOLING_FREQUENCY=5 -e JMXTRANS_LOG_LEVEL=INFO \
    "$IMAGE" >/dev/null

echo "Waiting for metrics..."
i=0
while [ "$i" -lt 40 ]; do
    out=$(docker exec "$NET-influx" influx -database exo -execute 'SHOW MEASUREMENTS' 2>/dev/null || true)
    case "$out" in *jvm_memory_heap*) break ;; esac
    i=$((i + 1))
    sleep 3
done
echo "$out"
case "$out" in *jvm_memory_heap*) ;; *) echo "FAIL: no jvm_memory_heap measurement"; docker logs "$NET-jmxtrans" | tail -30; exit 1 ;; esac

# metrics flowing is not enough: startup problems (e.g. a missing native library
# for the config watcher) are logged but not fatal
if docker logs "$NET-jmxtrans" 2>&1 | grep -E 'UnsatisfiedLinkError|Exception'; then
    echo "FAIL: errors in the jmxtrans startup log"
    exit 1
fi
echo "startup log clean: OK"

docker exec "$NET-jmxtrans" /opt/jmxtrans/healthcheck.sh && echo "healthcheck: OK"
docker exec "$NET-jmxtrans" ps -o user,args | grep -q '^nobody.*java' && echo "runs as nobody: OK"
echo "PASS"
