# JMXTrans docker container for eXo

This container aims to provide an out of the box tool to collect eXo Platform JMX metrics and to push it in an Influxdb server.

# Image tags

[![Docker Stars](https://img.shields.io/docker/stars/exoplatform/jmxtrans.svg)]() - [![Docker Pulls](https://img.shields.io/docker/pulls/exoplatform/jmxtrans.svg)]()

|    Image                          |  JMXTrans  |   Java  |   eXo Platform
|-----------------------------------|------------|---------|--------------------
| exoplatform/jmxtrans:latest       |   272      |   17    |   6.2+
| exoplatform/jmxtrans:272_N        |   272      |   17    |   6.2+ (`272_4` to `272_7` ran on Java 11)
| exoplatform/jmxtrans:268_1        |   268      |   11    |   5.1+
| exoplatform/jmxtrans:268_0        |   268      |   11    |   4.4+

The `latest` tag is rebuilt on every push to `master`; versioned tags are published from `N_M` git tags.


# Running

Just launch the image with default values :

```
docker run exoplatform/jmxtrans 
```

If you want to specify the targeted Influxdb server :

```
docker run -e TARGET_INFLUXDB_URL="http://influxdb.server.org" exoplatform/jmxtrans 
```

or the eXo Platform server hostname :

```
docker run -e TARGET_JMX_HOST=exo.server.org exoplatform/jmxtrans 
```

For more configuration settings, see the next section.

# Configuration options

Several aspects of JMXTrans container are customizable with the following environment variables:

|    VARIABLE              |  MANDATORY  |   DEFAULT VALUE          |  DESCRIPTION
|--------------------------|-------------|--------------------------|----------------
| HEAP_SIZE | NO | `512` | specify the jvm allocated memory size in MB (-Xms and -Xmx parameters)
| TARGET_JMX_HOST | NO | `localhost` | the JMX hostname of the eXo Platform instance
| TARGET_JMX_PORT | NO | `8004` | the JMX port of the eXo Platform instance
| TARGET_JMX_USER | NO | `nobody` | the JMX username of the eXo Platform instance (a dummy value is needed because the JSON configs reference it; it is ignored when the target has no JMX authentication)
| TARGET_JMX_PASSWORD | NO | `nothing` | the JMX password of the eXo Platform instance
| TARGET_HOSTNAME | NO | `same as $TARGET_JMX_HOST value` | the hostname of the eXo Platform server
| TARGET_NODE_ID | NO | `NC` | a string to identify an eXo node in a cluster for exemple
| TARGET_INFLUXDB_URL | NO | `http://localhost:8086` | the full url of the Influxdb server to send the metrics
| TARGET_INFLUXDB_DATABASE | NO | `exo` | the Influxdb database name to use
| TARGET_INFLUXDB_USERNAME | NO | `nobody` | the Influxdb username
| TARGET_INFLUXDB_PASSWORD | NO | `nothing` | the Influxdb password
| TARGET_INFLUXDB_CREATE_DB | NO | `true` | does JMXTrans create the Influxdb database if needed
| TARGET_INFLUXDB_RETENTION_POLICY | NO | `autogen` | the Influxdb rentention policy name to use
| JMXTRANS_POOLING_FREQUENCY | NO | `30` | the JMXTrans polling frequency in seconds
| JMXTRANS_LOG_LEVEL | NO | `WARN` | the JMXTrans logging level (DEBUG|INFO|WARN|ERROR|FATAL)

Credentials are handed to JMXTrans as JVM system properties (the JSON configs reference them as `${TARGET_*}`), so they are visible in the process arguments inside the container. Do not share the container's PID namespace with untrusted workloads.

# Health check

The image ships a health check (`/opt/jmxtrans/healthcheck.sh`) that is healthy only when the JMXTrans JVM is running, the InfluxDB `/ping` endpoint answers and the target JMX port accepts connections.

# Testing

* `test/smoke.sh [image]` runs the image against a real JMX endpoint and a real InfluxDB and checks that metrics are written. CI runs it on every pull request.
* `docker compose -f test/docker-compose.yml up --build` starts a complete eXo Platform + JMXTrans + InfluxDB + Grafana stack (the InfluxDB datasource is provisioned in Grafana).
  Grafana is on http://localhost:3000 with anonymous read-only access, and six dashboards are provisioned in the `eXo` folder from `test/grafana/dashboards/`: *Overview* (all hosts side by side), *JVM*, *Tomcat and caches*, *Caches* (per-cache selector, hit ratio, misses, capacity), *JCR and Infinispan* and *Database pools*. Edit the JSON files to change them; Grafana reloads them every 30 seconds.

# Collected metrics

| Influxdb Measurement | MBeans 
|----------------------|--------
| jvm_gc | java.lang:type=GarbageCollector,name=* 
| jvm_memory_heap | java.lang:type=Memory 
| jvm_memory_pool | java.lang:name=*,type=MemoryPool 
| jvm_system | java.lang:type=OperatingSystem 
| jvm_threads| java.lang:type=Threading 
| exo_caches | exo:portal=*,service=cache,name=*
| exo_infinispan_idm | org.infinispan.plidm:type=Cache,name=*,manager=*,component=Statistics
| exo_infinispan_idm_channel | org.infinispan.plidm:type=channel,cluster=*
| exo_infinispan_idm_protocol | org.infinispan.plidm:type=protocol,cluster=*,protocol=TCP
| exo_infinispan_idm_rpc | org.infinispan.plidm:type=Cache,name=*,manager=*,component=RpcManager
| exo_infinispan_jcr | jcr.ispn.cache:type=Cache,name=*,manager=*,component=Statistics
| exo_infinispan_jcr_channel | jcr.ispn.cache:type=channel,cluster=*
| exo_infinispan_jcr_protocol | jcr.ispn.cache:type=protocol,cluster=*,protocol=TCP
| exo_infinispan_jcr_rpc | jcr.ispn.cache:type=Cache,name=*,manager=*,component=RpcManager
| exo_infinispan_services | services.ispn.cache:type=Cache,name=*,manager=*,component=Statistics
| exo_infinispan_services_channel | services.ispn.cache:type=channel,cluster=*
| exo_infinispan_services_protocol | services.ispn.cache:type=protocol,cluster=*,protocol=TCP
| exo_infinispan_services_rpc | services.ispn.cache:type=Cache,name=*,manager=*,component=RpcManager
| exo_jcr_cache | exo:portal=*,repository=*,workspace=*,service=Cache <br> exo:portal=*,repository=*,workspace=*,service=lockmanager
| exo_jcr_session_registry | exo:portal=*,repository=*,service=SessionRegistry
| tomcat_datasources | Catalina:type=DataSource,class=javax.sql.DataSource,name=\"*\"
| tomcat_request_processor | Catalina:type=GlobalRequestProcessor,name=*
| tomcat_http_sessions | Catalina:type=Manager,context=/*,host=*
| tomcat_threadpools | Catalina:type=ThreadPool,name=*


# Testing

A docker-compose file is provided to test a full monitoring stack with eXo Platform Community edition

```
docker-compose -f test/docker-compose.yml -p jmx up -d
```
