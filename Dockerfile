FROM alpine:latest AS s6-builder

ARG TARGETPLATFORM

RUN echo "**** upgrade packages ****" \
    && apk --no-cache --no-progress upgrade \
    && echo "**** install packages ****" \
    && apk --no-cache --no-progress add tar \
    && echo "**** create folders ****" \
    && mkdir -p /s6 \
    && echo "**** download s6 overlay ****"
RUN S6_ARCH=$(case ${TARGETPLATFORM} in \
        "linux/amd64")    echo "amd64"    ;; \
        "linux/386")      echo "x86"      ;; \
        "linux/arm64")    echo "aarch64"  ;; \
        "linux/arm/v7")   echo "armhf"    ;; \
        "linux/arm/v6")   echo "arm"      ;; \
        "linux/ppc64le")  echo "ppc64le"  ;; \
        *)                echo ""         ;; esac) \
    && echo "s6 overlay platform selected "$S6_ARCH \
    && wget -q https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${S6_ARCH}.tar.gz -qO /tmp/s6-overlay.tar.gz \
    && tar xfz /tmp/s6-overlay.tar.gz -C /s6/

FROM alpine:latest AS duplicacy-builder

ARG TARGETPLATFORM
ARG DUPLICACY_VERSION

RUN echo "**** upgrade packages ****" \
    && apk --no-cache --no-progress upgrade \
    && echo "**** download duplicacy ****"
RUN DUPLICACY_ARCH=$(case ${TARGETPLATFORM} in \
        "linux/amd64")  echo "x64"    ;; \
        "linux/386")    echo "i386"   ;; \
        "linux/arm64")  echo "arm64"  ;; \
        "linux/arm/v7") echo "arm"    ;; \
        "linux/arm/v6") echo "arm"    ;; \
        *)              echo ""       ;; esac) \
    && echo "Duplicacy platform selected "$DUPLICACY_ARCH \
    && wget -q https://github.com/gilbertchen/duplicacy/releases/latest/download/duplicacy_linux_${DUPLICACY_ARCH}_${DUPLICACY_VERSION} -qO /tmp/duplicacy

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
