# s6 overlay builder
FROM alpine:3.15.0 AS s6-builder

ENV PACKAGE="just-containers/s6-overlay"
ENV PACKAGEVERSION="2.2.0.3"
ARG TARGETPLATFORM

RUN echo "**** install mandatory packages ****" && \
    apk --no-cache --no-progress add tar=1.34-r0 && \
    echo "**** create folders ****" && \
    mkdir -p /s6 && \
    echo "**** download ${PACKAGE} ****" && \
    PACKAGEPLATFORM=$(case ${TARGETPLATFORM} in \
        "linux/amd64")    echo "amd64"    ;; \
        "linux/386")      echo "x86"      ;; \
        "linux/arm64")    echo "aarch64"  ;; \
        "linux/arm/v7")   echo "armhf"    ;; \
        "linux/arm/v6")   echo "arm"      ;; \
        "linux/ppc64le")  echo "ppc64le"  ;; \
        *)                echo ""         ;; esac) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${PACKAGEVERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-${PACKAGEPLATFORM}.tar.gz" -qO /tmp/s6-overlay.tar.gz && \
    tar xfz /tmp/s6-overlay.tar.gz -C /s6/

# Duplicacy builder
FROM alpine:3.15.0 AS duplicacy-builder

ENV PACKAGE="gilbertchen/duplicacy"
ENV PACKAGEVERSION="2.7.2"
ARG TARGETPLATFORM

RUN echo "**** download ${PACKAGE} ****" && \
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
FROM alpine:3.15.0 AS rootfs-builder

COPY root/ /rootfs/
COPY --from=duplicacy-builder /tmp/duplicacy /rootfs/usr/bin/duplicacy
RUN chmod +x /rootfs/usr/bin/*
COPY --from=s6-builder /s6/ /rootfs/

# Main image
FROM alpine:3.15.0

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    PRIORITY_LEVEL=10 \
    EMAIL_LOG_LINES_IN_BODY=10

RUN echo "**** install mandatory packages ****" && \
    apk --no-cache --no-progress add bash=5.1.8-r0 \
        zip=3.0-r9 \
        ssmtp=2.64-r16 \
        ca-certificates=20211220-r0 \
        docker=20.10.11-r0 && \
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
