# JMXTrans docker container for eXo

This container aims to provide an out of the box tool to collect eXo Platform JMX metrics and to push it in an Influxdb server.

# eXo Platform Docker image

[![Docker Stars](https://img.shields.io/docker/stars/exoplatform/jmxtrans.svg)]() - [![Docker Pulls](https://img.shields.io/docker/pulls/exoplatform/jmxtrans.svg)]()

|    Image                          |  JMXTrans  |   eXo Platform    
|-----------------------------------|------------|--------------------
| exoplatform/jmxtrans:latest       |   265      |   4.4+
| exoplatform/jmxtrans:develop      |   265      |   4.4+

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
| TARGET_HOSTNAME | NO | `same as $TARGET_JMX_HOST value` | the hostname of the eXo Platform server
| TARGET_NODE_ID | NO | `NC` | a string to identify an eXo node in a cluster for exemple
| TARGET_INFLUXDB_URL | NO | `http://localhost:8086` | the full url of the Influxdb server to send the metrics
| TARGET_INFLUXDB_DATABASE | NO | `exo` | the Influxdb database name to use
| TARGET_INFLUXDB_USERNAME | NO | `nobody` | the Influxdb username
| TARGET_INFLUXDB_PASSWORD | NO | `nothing` | the Influxdb password
| TARGET_INFLUXDB_CREATE_DB | NO | `true` | does JMXTrans create the Influxdb database if needed
| TARGET_INFLUXDB_RETENTION_POLICY | NO | `autogen` | the Influxdb rentention policy name to use
| JMXTRANS_POOLING_FREQUENCY | NO | `30` | the JMXTrans pooling frequency in seconds
| JMXTRANS_LOG_LEVEL | NO | `WARN` | the JMXTrans logging level (DEBUG|INFO|WARN|ERROR|FATAL)

# Collected metrics

| Influxdb Measurement | MBeans 
|----------------------|--------
| jvm_gc | java.lang:type=GarbageCollector,name=* 
| jvm_memory_heap | java.lang:type=Memory 
| jvm_memory_pool | java.lang:name=*,type=MemoryPool 
| jvm_system | java.lang:type=OperatingSystem 
| jvm_threads| java.lang:type=Threading 
| tomcat_datasources | Catalina:type=DataSource,class=javax.sql.DataSource,name=\"*\"
| tomcat_request_processor | Catalina:type=GlobalRequestProcessor,name=*
| tomcat_http_sessions | Catalina:type=Manager,context=/*,host=*
| tomcat_threadpools | Catalina:type=ThreadPool,name=*


# Testing

A docker-compose file is provided to test a full monitoring stack with eXo Platform Community edition

```
docker-compose -f test/docker-compose.yml -p jmx up -d
```
