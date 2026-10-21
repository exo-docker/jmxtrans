# Java Docker container optimized with multi-stage build
# Source: http://heiber.im/post/creating-a-solid-docker-base-image/
# Build: docker build -t exoplatform/jmxtrans:latest .

# Stage 1: Builder Stage (download and verify the jmxtrans jar)
FROM alpine:3@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS builder

ARG JMXTRANS_VERSION=272
ARG JMXTRANS_SHA256=23cd3795e941c4d4624030aab4708d736e74e61f38868ce943e5cfac880ed704

RUN apk add --no-cache ca-certificates curl

WORKDIR /build

# Install JMXTrans
RUN set -ex \
    && curl -fsSLo jmxtrans-all.jar "https://repo.maven.apache.org/maven2/org/jmxtrans/jmxtrans/${JMXTRANS_VERSION}/jmxtrans-${JMXTRANS_VERSION}-all.jar" \
    && echo "${JMXTRANS_SHA256}  jmxtrans-all.jar" | sha256sum -c -

# Stage 2: Final Image
FROM azul/zulu-openjdk-alpine:20-jre-headless-latest@sha256:08b51edd555a2d9200bc075a554d306a8ef68d80c5b9532ef0b4e79dd9cc99ab

LABEL maintainer="eXo Platform <docker@exoplatform.com>" \
      org.opencontainers.image.title="jmxtrans" \
      org.opencontainers.image.description="JMXTrans collecting eXo Platform JMX metrics into InfluxDB" \
      org.opencontainers.image.source="https://github.com/exo-docker/jmxtrans" \
      org.opencontainers.image.licenses="MIT"

ENV TERM=xterm \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    JMXTRANS_APP_DIR=/opt/jmxtrans \
    JMXTRANS_JAR_FILE=jmxtrans-all.jar \
    JMXTRANS_JSON_DIR=/etc/jmxtrans \
    JMXTRANS_LOG_DIR=/var/log/jmxtrans

# libstdc++ and gcompat: the native jpathwatch library (config directory watcher) needs them
RUN apk add --no-cache tini curl libstdc++ gcompat

WORKDIR /opt/jmxtrans

# Copy files from the builder stage
COPY --from=builder /build/jmxtrans-all.jar ./jmxtrans-all.jar

COPY jmxtrans.sh healthcheck.sh logback.xml ./
COPY conf/ ${JMXTRANS_JSON_DIR}

RUN chmod +x ./jmxtrans.sh ./healthcheck.sh \
    && mkdir -p ${JMXTRANS_LOG_DIR} \
    && chown -R nobody:nogroup ${JMXTRANS_LOG_DIR}

USER nobody:nogroup

ENTRYPOINT ["/sbin/tini", "-g", "--"]
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s CMD ["/opt/jmxtrans/healthcheck.sh"]
CMD ["/opt/jmxtrans/jmxtrans.sh", "start", "/etc/jmxtrans"]
