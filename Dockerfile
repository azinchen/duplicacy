# s6 overlay builder
FROM alpine:3.16.0 AS s6-builder

ENV PACKAGE="just-containers/s6-overlay"
ENV PACKAGEVERSION="3.1.1.2"
ARG TARGETPLATFORM

RUN echo "**** install security fixes ****" && \
    apk --no-cache --no-progress add openssl=1.1.1q-r0 && \
    echo "**** install mandatory packages ****" && \
    apk --no-cache --no-progress add tar=1.34-r0 \
        xz=5.2.5-r1 && \
    echo "**** create folders ****" && \
    mkdir -p /s6 && \
    echo "**** download ${PACKAGE} ****" && \
    PACKAGEPLATFORM=$(case ${TARGETPLATFORM} in \
        "linux/amd64")    echo "x86_64"   ;; \
        "linux/386")      echo "i486"     ;; \
        "linux/arm64")    echo "aarch64"  ;; \
        "linux/arm/v7")   echo "armhf"    ;; \
        "linux/arm/v6")   echo "arm"      ;; \
        *)                echo ""         ;; esac) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${PACKAGEVERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-noarch.tar.xz" -qO /tmp/s6-overlay-noarch.tar.xz && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-${PACKAGEPLATFORM}.tar.xz" -qO /tmp/s6-overlay-binaries.tar.xz && \
    tar -C /s6/ -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C /s6/ -Jxpf /tmp/s6-overlay-binaries.tar.xz

# Duplicacy builder
FROM alpine:3.16.0 AS duplicacy-builder

ENV PACKAGE="gilbertchen/duplicacy"
ENV PACKAGEVERSION="2.7.2"
ARG TARGETPLATFORM

RUN echo "**** install security fixes ****" && \
    apk --no-cache --no-progress add openssl=1.1.1q-r0 && \
    echo "**** download ${PACKAGE} ****" && \
    PACKAGEPLATFORM=$(case ${TARGETPLATFORM} in \
        "linux/amd64")  echo "x64"    ;; \
        "linux/386")    echo "i386"   ;; \
        "linux/arm64")  echo "arm64"  ;; \
        "linux/arm/v7") echo "arm"    ;; \
        "linux/arm/v6") echo "arm"    ;; \
        *)              echo ""       ;; esac) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${PACKAGEVERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/duplicacy_linux_${PACKAGEPLATFORM}_${PACKAGEVERSION}" -qO /tmp/duplicacy

# rootfs builder
FROM alpine:3.16.0 AS rootfs-builder

RUN echo "**** install security fixes ****" && \
    apk --no-cache --no-progress add openssl=1.1.1q-r0

COPY root/ /rootfs/
COPY --from=duplicacy-builder /tmp/duplicacy /rootfs/usr/bin/duplicacy
RUN chmod +x /rootfs/usr/bin/*
COPY --from=s6-builder /s6/ /rootfs/

# Main image
FROM alpine:3.16.0

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    PRIORITY_LEVEL=10 \
    EMAIL_LOG_LINES_IN_BODY=10 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000

RUN echo "**** install security fixes ****" && \
    apk --no-cache --no-progress add containerd=1.6.6-r0 \
        openssl=1.1.1q-r0 && \
    echo "**** install mandatory packages ****" && \
    apk --no-cache --no-progress add bash=5.1.16-r2 \
        zip=3.0-r9 \
        ssmtp=2.64-r16 \
        ca-certificates=20211220-r0 \
        docker=20.10.16-r0 && \
    echo "**** create folders ****" && \
    mkdir -p /config && \
    mkdir -p /data && \
    echo "**** cleanup ****" && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*

COPY --from=rootfs-builder /rootfs/ /

VOLUME ["/config"]
VOLUME ["/data"]

WORKDIR  /config

ENTRYPOINT ["/init"]
