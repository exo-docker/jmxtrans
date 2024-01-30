# Java docker container
# source: http://heiber.im/post/creating-a-solid-docker-base-image/
#
# build: docker build -t exoplatform/jmxtrans:latest .
FROM    eclipse-temurin:11-jdk-alpine
LABEL   maintainer="eXo Platform <docker@exoplatform.com>"

ARG JMXTRANS_VERSION=272
ENV GOSU_VERSION 1.17

RUN apk update && \
    apk upgrade && \
    apk add --no-cache --virtual .gosu-deps \
		dpkg \
        ca-certificates \
		gnupg && \
    apk add --no-cache tini curl libstdc++ gcompat bash

ENV TERM=xterm \
    # Local
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    # JMXTrans
    JMXTRANS_APP_DIR=/opt/jmxtrans \
    JMXTRANS_JAR_FILE=jmxtrans-all.jar \
    JMXTRANS_JSON_DIR=/etc/jmxtrans \
    LOG_DIR=/var/log/jmxtrans \
    PATH=${PATH}:/opt

WORKDIR /tmp

# Installing Gosu
RUN set -ex \
    && ( gpg --batch --keyserver keyserver.ubuntu.com     --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
        || gpg --batch --keyserver keyserver.pgp.com        --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
        || gpg --batch --keyserver keys.openpgp.org         --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    )

RUN set -ex \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }').asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

# Installing JMXTrans
RUN set -eux \
    echo "Downloading https://repo.maven.apache.org/maven2/org/jmxtrans/jmxtrans/${JMXTRANS_VERSION}/jmxtrans-${JMXTRANS_VERSION}-all.jar" \
    && mkdir -p "${JMXTRANS_APP_DIR}" \
    && curl -Lo "${JMXTRANS_APP_DIR}/${JMXTRANS_JAR_FILE}" "https://repo.maven.apache.org/maven2/org/jmxtrans/jmxtrans/${JMXTRANS_VERSION}/jmxtrans-${JMXTRANS_VERSION}-all.jar" \
    && mkdir -p ${LOG_DIR} \
    && rm -rf /tmp/*

# Cleanup
RUN apk del --no-network .gosu-deps

COPY jmxtrans.sh ${JMXTRANS_APP_DIR}/jmxtrans.sh
COPY logback.xml ${JMXTRANS_APP_DIR}/logback.xml
COPY conf/ ${JMXTRANS_JSON_DIR}

RUN chmod +x ${JMXTRANS_APP_DIR}/jmxtrans.sh

ENTRYPOINT ["/sbin/tini", "--"]
HEALTHCHECK CMD curl --fail ${TARGET_INFLUXDB_URL:-"http://localhost:8086"}/ping && timeout 2 /bin/bash -c "</dev/tcp/${TARGET_JMX_HOST:-localhost}/${TARGET_JMX_PORT:-8004}" || exit 1
CMD ["/opt/jmxtrans/jmxtrans.sh", "start", "/etc/jmxtrans"]
