FROM alpine:latest

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    THREADS_NUM="1"

RUN echo "**** upgrade packages ****" && \
    apk --no-cache --no-progress upgrade && \
    echo "**** install packages ****" && \
    apk --no-cache --no-progress add bash curl tar && \
    echo "**** add s6 overlay ****" && \
    curl -o /tmp/s6-overlay.tar.gz -L \
        "https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz" && \
    tar xfz /tmp/s6-overlay.tar.gz -C / && \
    echo "**** download duplicacy binary ****" && \
    curl -o /usr/bin/duplicacy -L \
        "https://github.com/gilbertchen/duplicacy/releases/download/v2.2.3/duplicacy_linux_x64_2.2.3" && \
    chmod +x /usr/bin/duplicacy && \
    echo "**** create folders ****" && \
    mkdir -p /config && \
    mkdir -p /data && \
    echo "**** cleanup ****" && \
    apk del --purge tar curl && \
    rm -rf /tmp/*

COPY root/ /

RUN chmod +x /app/*

VOLUME ["/config"]
VOLUME ["/data"]

WORKDIR  /config

ENTRYPOINT ["/init"]
