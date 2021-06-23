# s6 overlay builder
FROM alpine:latest AS s6-builder

ENV PACKAGE="just-containers/s6-overlay"
ARG TARGETPLATFORM
COPY /github_packages.json /tmp/github_packages.json

RUN echo "**** upgrade packages ****" \
    && apk --no-cache --no-progress upgrade \
    && echo "**** install packages ****" \
    && apk --no-cache --no-progress add tar jq \
    && echo "**** create folders ****" \
    && mkdir -p /s6 \
    && echo "**** download s6 overlay ****" \
    && ARCH=$(case ${TARGETPLATFORM} in \
        "linux/amd64")    echo "amd64"    ;; \
        "linux/386")      echo "x86"      ;; \
        "linux/arm64")    echo "aarch64"  ;; \
        "linux/arm/v7")   echo "armhf"    ;; \
        "linux/arm/v6")   echo "arm"      ;; \
        "linux/ppc64le")  echo "ppc64le"  ;; \
        *)                echo ""         ;; esac) \
    && echo "${PACKAGE} platform selected $ARCH" \
    && VERSION=$(jq -r '.[] | select(.name == "'${PACKAGE}'").version' /tmp/github_packages.json) \
    && echo "${PACKAGE} version selected $VERSION" \
    && wget -q https://github.com/${PACKAGE}/releases/download/v${VERSION}/s6-overlay-${ARCH}.tar.gz -qO /tmp/s6-overlay.tar.gz \
    && tar xfz /tmp/s6-overlay.tar.gz -C /s6/

# Duplicacy builder
FROM alpine:latest AS duplicacy-builder

ENV PACKAGE="gilbertchen/duplicacy"
ARG TARGETPLATFORM
COPY /github_packages.json /tmp/github_packages.json

RUN echo "**** upgrade packages ****" \
    && apk --no-cache --no-progress upgrade \
    && echo "**** install packages ****" \
    && apk --no-cache --no-progress add jq \
    && echo "**** download duplicacy ****" \
    && ARCH=$(case ${TARGETPLATFORM} in \
        "linux/amd64")  echo "x64"    ;; \
        "linux/386")    echo "i386"   ;; \
        "linux/arm64")  echo "arm64"  ;; \
        "linux/arm/v7") echo "arm"    ;; \
        "linux/arm/v6") echo "arm"    ;; \
        *)              echo ""       ;; esac) \
    && echo "${PACKAGE} platform selected $ARCH" \
    && VERSION=$(jq -r '.[] | select(.name == "'${PACKAGE}'").version' /tmp/github_packages.json) \
    && echo "${PACKAGE} version selected $VERSION" \
    && wget -q https://github.com/${PACKAGE}/releases/download/v${VERSION}/duplicacy_linux_${ARCH}_${VERSION} -qO /tmp/duplicacy

# Main image
FROM alpine:latest

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    PRIORITY_LEVEL=10 \
    EMAIL_LOG_LINES_IN_BODY=10

RUN echo "**** upgrade packages ****" \
    && apk --no-cache --no-progress upgrade \
    && echo "**** install packages ****" \
    && apk --no-cache --no-progress add bash zip ssmtp ca-certificates docker \
    && echo "**** create folders ****" \
    && mkdir -p /config \
    && mkdir -p /data \
    && echo "**** cleanup ****" \
    && rm -rf /tmp/* \
    && rm -rf /var/cache/apk/*

COPY --from=s6-builder /s6/ /
COPY --from=duplicacy-builder /tmp/duplicacy /usr/bin/duplicacy
COPY root/ /

RUN chmod +x /app/*
RUN chmod +x /usr/bin/duplicacy

VOLUME ["/config"]
VOLUME ["/data"]

WORKDIR  /config

ENTRYPOINT ["/init"]
