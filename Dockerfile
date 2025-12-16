# s6 overlay builder
FROM alpine:3.23.0 AS s6-builder

ENV PACKAGE="just-containers/s6-overlay"
ENV PACKAGEVERSION="3.2.1.0"
ARG TARGETPLATFORM

RUN echo "**** install security fix packages ****" && \
    echo "**** install mandatory packages ****" && \
    apk --no-cache --no-progress add \
        tar=1.35-r3 \
        xz=5.8.1-r0 \
        && \
    echo "**** create folders ****" && \
    mkdir -p /s6 && \
    echo "**** download ${PACKAGE} ****" && \
    PACKAGEPLATFORM=$(case ${TARGETPLATFORM} in \
        "linux/386")      echo "i486"     ;; \
        "linux/amd64")    echo "x86_64"   ;; \
        "linux/arm/v6")   echo "arm"      ;; \
        "linux/arm/v7")   echo "armhf"    ;; \
        "linux/arm64")    echo "aarch64"  ;; \
        *)                echo ""         ;; esac) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${PACKAGEVERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-noarch.tar.xz" -qO /tmp/s6-overlay-noarch.tar.xz && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-${PACKAGEPLATFORM}.tar.xz" -qO /tmp/s6-overlay-binaries.tar.xz && \
    tar -C /s6/ -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C /s6/ -Jxpf /tmp/s6-overlay-binaries.tar.xz

# Duplicacy builder
FROM alpine:3.23.0 AS duplicacy-builder

ENV PACKAGE="gilbertchen/duplicacy"
ENV PACKAGEVERSION="3.2.5"
ARG TARGETPLATFORM

RUN echo "**** install security fix packages ****" && \
    echo "**** download ${PACKAGE} ****" && \
    PACKAGEPLATFORM=$(case ${TARGETPLATFORM} in \
        "linux/386")    echo "i386"   ;; \
        "linux/amd64")  echo "x64"    ;; \
        "linux/arm/v6") echo "arm"    ;; \
        "linux/arm/v7") echo "arm"    ;; \
        "linux/arm64")  echo "arm64"  ;; \
        *)              echo ""       ;; esac) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${PACKAGEVERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/duplicacy_linux_${PACKAGEPLATFORM}_${PACKAGEVERSION}" -qO /tmp/duplicacy

# rootfs builder
FROM alpine:3.23.0 AS rootfs-builder

RUN echo "**** install security fix packages ****" && \
    echo "**** end run statement ****"

COPY root/ /rootfs/
COPY --from=duplicacy-builder /tmp/duplicacy /rootfs/usr/bin/duplicacy
RUN chmod +x /rootfs/usr/bin/*
COPY --from=s6-builder /s6/ /rootfs/

# Main image
FROM alpine:3.23.0

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    EMAIL_LOG_LINES_IN_BODY=10 \
    SEND_REPORT_LEVEL="all" \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000

RUN echo "**** install security fix packages ****" && \
    echo "**** install mandatory packages ****" && \
    apk --no-cache --no-progress add \
        bash=5.2.37-r0 \
        tzdata=2025c-r0 \
        zip=3.0-r13 \
        ssmtp=2.64-r22 \
        ca-certificates=20250911-r0 \
        docker-cli=28.3.3-r4 \
        && \
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
