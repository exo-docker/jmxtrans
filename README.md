# JMXTrans for eXo Platform

Collects eXo Platform JMX metrics into InfluxDB v2 via a **JMXTrans → Graphite → Telegraf → InfluxDB v2** pipeline.

[![Docker Stars](https://img.shields.io/docker/stars/exoplatform/jmxtrans.svg)]() - [![Docker Pulls](https://img.shields.io/docker/pulls/exoplatform/jmxtrans.svg)]()

## Architecture

```
eXo Platform (JMX RMI)
        │
        ▼
    JMXTrans ──Graphite──▶ Telegraf ──Line Protocol──▶ InfluxDB v2 ──▶ Grafana
```

- **JMXTrans** connects to the eXo JVM via JMX RMI and sends metrics as Graphite plaintext
- **Telegraf** receives Graphite metrics and forwards them to InfluxDB v2
- **InfluxDB v2** stores time-series data
- **Grafana** visualizes dashboards

## Image Tags

| Image | JMXTrans | eXo Platform |
|-------|----------|--------------|
| exoplatform/jmxtrans:latest | 272 | 4.4+ |
| exoplatform/jmxtrans:develop | 272 | 4.4+ |
| exoplatform/jmxtrans:272_4 | 272 | 6.2+ |

## Running

Standalone container:

```bash
docker run -e TARGET_JMX_HOST=exo.server.org \
           -e TARGET_GRAPHITE_HOST=telegraf.server.org \
           exoplatform/jmxtrans
```

Full monitoring stack:

```bash
cp test/.env.example test/.env
docker compose -f test/docker-compose.yml -p jmx up -d
```

Access Grafana at `http://localhost:3000` (default: admin/admin).

## Configuration

### JMXTrans Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HEAP_SIZE` | `512` | JVM heap size in MB |
| `TARGET_JMX_HOST` | `localhost` | eXo JMX hostname |
| `TARGET_JMX_PORT` | `8004` | eXo JMX port |
| `TARGET_JMX_USER` | | JMX username |
| `TARGET_JMX_PASSWORD` | | JMX password |
| `TARGET_HOSTNAME` | same as `TARGET_JMX_HOST` | Hostname label in metrics |
| `TARGET_NODE_ID` | `NC` | Cluster node identifier |
| `TARGET_GRAPHITE_HOST` | `localhost` | Telegraf/Graphite target host |
| `TARGET_GRAPHITE_PORT` | `2003` | Telegraf/Graphite target port |
| `TARGET_GRAPHITE_ROOT_PREFIX` | `jmxtrans.<host>.<node>` | Metric path prefix |
| `JMXTRANS_POOLING_FREQUENCY` | `30` | Collection interval in seconds |
| `JMXTRANS_LOG_LEVEL` | `WARN` | Log level (DEBUG/INFO/WARN/ERROR) |

### InfluxDB v2 Environment Variables (docker-compose)

| Variable | Default | Description |
|----------|---------|-------------|
| `INFLUXDB_ADMIN_USER` | `admin` | InfluxDB admin username |
| `INFLUXDB_ADMIN_PASSWORD` | `admin1234` | InfluxDB admin password |
| `INFLUXDB_ORG` | `exo` | InfluxDB organization |
| `INFLUXDB_BUCKET` | `exo` | InfluxDB bucket |
| `INFLUXDB_TOKEN` | `exo-influxdb-token` | InfluxDB API token |

### Grafana (docker-compose)

| Variable | Default | Description |
|----------|---------|-------------|
| `GRAFANA_ADMIN_USER` | `admin` | Grafana admin username |
| `GRAFANA_ADMIN_PASSWORD` | `admin` | Grafana admin password |

## Collected Metrics

| Measurement | MBean |
|-------------|-------|
| `jvm_gc` | `java.lang:type=GarbageCollector,name=*` |
| `jvm_memory_heap` | `java.lang:type=Memory` |
| `jvm_memory_pool` | `java.lang:name=*,type=MemoryPool` |
| `jvm_system` | `java.lang:type=OperatingSystem` |
| `jvm_threads` | `java.lang:type=Threading` |
| `exo_cache` | `exo:portal=*,service=cache,name=*` |
| `exo_infinispan_idm` | `org.infinispan.plidm:type=Cache,name=*,manager=*,component=Statistics` |
| `exo_infinispan_idm_channel` | `org.infinispan.plidm:type=channel,cluster=*` |
| `exo_infinispan_idm_protocol` | `org.infinispan.plidm:type=protocol,cluster=*,protocol=TCP` |
| `exo_infinispan_idm_rpc` | `org.infinispan.plidm:type=Cache,name=*,manager=*,component=RpcManager` |
| `exo_infinispan_jcr` | `jcr.ispn.cache:type=Cache,name=*,manager=*,component=Statistics` |
| `exo_infinispan_jcr_channel` | `jcr.ispn.cache:type=channel,cluster=*` |
| `exo_infinispan_jcr_protocol` | `jcr.ispn.cache:type=protocol,cluster=*,protocol=TCP` |
| `exo_infinispan_jcr_rpc` | `jcr.ispn.cache:type=Cache,name=*,manager=*,component=RpcManager` |
| `exo_infinispan_services` | `services.ispn.cache:type=Cache,name=*,manager=*,component=Statistics` |
| `exo_infinispan_services_channel` | `services.ispn.cache:type=channel,cluster=*` |
| `exo_infinispan_services_protocol` | `services.ispn.cache:type=protocol,cluster=*,protocol=TCP` |
| `exo_infinispan_services_rpc` | `services.ispn.cache:type=Cache,name=*,manager=*,component=RpcManager` |
| `exo_jcr_cache` | `exo:portal=*,repository=*,workspace=*,service=Cache` / `service=lockmanager` |
| `exo_jcr_session_registry` | `exo:portal=*,repository=*,service=SessionRegistry` |
| `tomcat_datasources` | `Catalina:type=DataSource,class=javax.sql.DataSource,name="*"` |
| `tomcat_request_processor` | `Catalina:type=GlobalRequestProcessor,name=*` |
| `tomcat_http_sessions` | `Catalina:type=Manager,context=/*,host=*` |
| `tomcat_threadpools` | `Catalina:type=ThreadPool,name=*` |
