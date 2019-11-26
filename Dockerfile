FROM alpine:latest

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    EMAIL_LOG_LINES_IN_BODY=10

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz
ADD https://github.com/gilbertchen/duplicacy/releases/download/v2.3.0/duplicacy_linux_x64_2.3.0 /usr/bin/duplicacy

RUN echo "**** upgrade packages ****" && \
    apk --no-cache --no-progress upgrade && \
    echo "**** install packages ****" && \
    apk --no-cache --no-progress add bash tar zip ssmtp && \
    echo "**** add s6 overlay ****" && \
    tar xfz /tmp/s6-overlay.tar.gz -C / && \
    echo "**** add duplicacy binary ****" && \
    chmod +x /usr/bin/duplicacy && \
    echo "**** create folders ****" && \
    mkdir -p /config && \
    mkdir -p /data && \
    echo "**** cleanup ****" && \
    apk del --purge tar && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*

COPY root/ /

RUN chmod +x /app/*

VOLUME ["/config"]
VOLUME ["/data"]

WORKDIR  /config

ENTRYPOINT ["/init"]
