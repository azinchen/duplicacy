# s6 overlay builder
FROM alpine:3.14 AS s6-builder

ENV PACKAGE="just-containers/s6-overlay"
ARG TARGETPLATFORM
COPY /github_packages.json /tmp/github_packages.json

RUN echo "**** install packages ****" && \
    apk --no-cache --no-progress add tar=1.34-r0 \
        jq=1.6-r1 && \
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
    VERSION=$(jq -r '.[] | select(.name == "'${PACKAGE}'").version' /tmp/github_packages.json) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${VERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${VERSION}/s6-overlay-${PACKAGEPLATFORM}.tar.gz" -qO /tmp/s6-overlay.tar.gz && \
    tar xfz /tmp/s6-overlay.tar.gz -C /s6/

# Duplicacy builder
FROM alpine:3.14 AS duplicacy-builder

ENV PACKAGE="gilbertchen/duplicacy"
ARG TARGETPLATFORM
COPY /github_packages.json /tmp/github_packages.json

RUN echo "**** install packages ****" && \
    apk --no-cache --no-progress add jq=1.6-r1 && \
    echo "**** download ${PACKAGE} ****" && \
    PACKAGEPLATFORM=$(case ${TARGETPLATFORM} in \
        "linux/amd64")  echo "x64"    ;; \
        "linux/386")    echo "i386"   ;; \
        "linux/arm64")  echo "arm64"  ;; \
        "linux/arm/v7") echo "arm"    ;; \
        "linux/arm/v6") echo "arm"    ;; \
        *)              echo ""       ;; esac) && \
    VERSION=$(jq -r '.[] | select(.name == "'${PACKAGE}'").version' /tmp/github_packages.json) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${VERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${VERSION}/duplicacy_linux_${PACKAGEPLATFORM}_${VERSION}" -qO /tmp/duplicacy

# rootfs builder
FROM alpine:3.14 AS rootfs-builder

COPY root/ /rootfs/
COPY --from=duplicacy-builder /tmp/duplicacy /rootfs/usr/bin/duplicacy
RUN chmod +x /rootfs/usr/bin/*
COPY --from=s6-builder /s6/ /rootfs/

# Main image
FROM alpine:3.14

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    PRIORITY_LEVEL=10 \
    EMAIL_LOG_LINES_IN_BODY=10

RUN echo "**** install packages ****" && \
    apk --no-cache --no-progress add bash=5.1.4-r0 \
        zip=3.0-r9 \
        ssmtp=2.64-r14 \
        ca-certificates=20191127-r5 \
        docker=20.10.7-r1 && \
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
