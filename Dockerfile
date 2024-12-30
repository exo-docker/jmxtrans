# Java Docker container optimized with multi-stage build
# Source: http://heiber.im/post/creating-a-solid-docker-base-image/
# Build: docker build -t exoplatform/jmxtrans:latest .

# Stage 1: Builder Stage
FROM azul/zulu-openjdk-alpine:11-jre-headless-latest AS builder

LABEL maintainer="eXo Platform <docker@exoplatform.com>"

ARG JMXTRANS_VERSION=272
ENV GOSU_VERSION=1.17

RUN apk add --no-cache --virtual .build-deps \
    dpkg \
    ca-certificates \
    gnupg \
    curl \
    && apk add --no-cache libstdc++ gcompat bash

WORKDIR /build

# Install Gosu
RUN set -ex \
    && ( gpg --batch --keyserver keyserver.ubuntu.com     --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    || gpg --batch --keyserver keyserver.pgp.com        --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    || gpg --batch --keyserver keys.openpgp.org         --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 ) \
    && curl -o gosu -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && curl -o gosu.asc -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }').asc" \
    && gpg --verify gosu.asc \
    && chmod +x gosu

# Install JMXTrans
RUN set -ex \
    && mkdir -p /opt/jmxtrans \
    && curl -Lo /opt/jmxtrans/jmxtrans-all.jar "https://repo.maven.apache.org/maven2/org/jmxtrans/jmxtrans/${JMXTRANS_VERSION}/jmxtrans-${JMXTRANS_VERSION}-all.jar"

# Stage 2: Final Image
FROM azul/zulu-openjdk-alpine:11-jre-headless-latest

LABEL maintainer="eXo Platform <docker@exoplatform.com>"

ENV TERM=xterm \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    JMXTRANS_APP_DIR=/opt/jmxtrans \
    JMXTRANS_JAR_FILE=jmxtrans-all.jar \
    JMXTRANS_JSON_DIR=/etc/jmxtrans \
    JMXTRANS_LOG_DIR=/var/log/jmxtrans \
    PATH=${PATH}:/opt

RUN apk add --no-cache tini curl libstdc++ gcompat bash

WORKDIR /opt/jmxtrans

# Copy files from the builder stage
COPY --from=builder /build/gosu /usr/local/bin/gosu
COPY --from=builder /opt/jmxtrans/jmxtrans-all.jar ./jmxtrans-all.jar

COPY jmxtrans.sh ./jmxtrans.sh
COPY logback.xml ./logback.xml
COPY conf/ ${JMXTRANS_JSON_DIR}

RUN chmod +x ./jmxtrans.sh \
    && mkdir -p ${JMXTRANS_LOG_DIR} \
    && chown -R nobody:nogroup ${JMXTRANS_LOG_DIR}

ENTRYPOINT ["/sbin/tini", "--"]
HEALTHCHECK CMD curl --fail ${TARGET_INFLUXDB_URL:-"http://localhost:8086"}/ping && timeout 2 /bin/bash -c "</dev/tcp/${TARGET_JMX_HOST:-localhost}/${TARGET_JMX_PORT:-8004}" || exit 1
CMD ["/opt/jmxtrans/jmxtrans.sh", "start", "/etc/jmxtrans"]
