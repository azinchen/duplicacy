# s6 overlay builder
FROM alpine:3.22.2 AS s6-builder

ENV PACKAGE="just-containers/s6-overlay"
ENV PACKAGEVERSION="3.2.1.0"

RUN echo "**** install security fix packages ****" && \
    echo "**** install mandatory packages ****" && \
    apk --no-cache --no-progress add \
        tar=1.35-r3 \
        xz=5.8.1-r0 \
        && \
    echo "**** create folders ****" && \
    mkdir -p /s6 && \
    echo "**** download ${PACKAGE} ****" && \
    s6_arch=$(case $(uname -m) in \
        i?86)           echo "i486"        ;; \
        x86_64)         echo "x86_64"      ;; \
        aarch64)        echo "aarch64"     ;; \
        armv6l)         echo "arm"         ;; \
        armv7l)         echo "armhf"       ;; \
        ppc64le)        echo "powerpc64le" ;; \
        riscv64)        echo "riscv64"     ;; \
        s390x)          echo "s390x"       ;; \
        *)              echo ""            ;; esac) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${PACKAGEVERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-noarch.tar.xz" -qO /tmp/s6-overlay-noarch.tar.xz && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-${s6_arch}.tar.xz" -qO /tmp/s6-overlay-binaries.tar.xz && \
    tar -C /s6/ -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C /s6/ -Jxpf /tmp/s6-overlay-binaries.tar.xz

# Duplicacy builder
FROM alpine:3.22.2 AS duplicacy-builder

ENV PACKAGE="gilbertchen/duplicacy"
ENV PACKAGEVERSION="3.2.5"
ARG TARGETPLATFORM

RUN echo "**** install security fix packages ****" && \
    echo "**** download ${PACKAGE} ****" && \
    duplicacy_arch=$(case $(uname -m) in \
        i?86)           echo "i386"        ;; \
        x86_64)         echo "x64"         ;; \
        aarch64)        echo "arm64"       ;; \
        armv6l)         echo "arm"         ;; \
        armv7l)         echo "arm"         ;; \
        *)              echo ""            ;; esac) && \
    echo "Package ${PACKAGE} platform ${duplicacy_arch} version ${PACKAGEVERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/duplicacy_linux_${duplicacy_arch}_${PACKAGEVERSION}" -qO /tmp/duplicacy

# rootfs builder
FROM alpine:3.22.2 AS rootfs-builder

RUN echo "**** install security fix packages ****" && \
    echo "**** end run statement ****"

COPY root/ /rootfs/
COPY --from=duplicacy-builder /tmp/duplicacy /rootfs/usr/local/bin/duplicacy
RUN chmod +x /rootfs/usr/local/bin/* || true && \
    chmod +x /rootfs/etc/s6-overlay/s6-rc.d/*/run  || true && \
    chmod +x /rootfs/etc/s6-overlay/s6-rc.d/*/finish || true
COPY --from=s6-builder /s6/ /rootfs/

# Main image
FROM alpine:3.22.2

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000

RUN echo "**** install security fix packages ****" && \
    echo "**** install mandatory packages ****" && \
    apk --no-cache --no-progress add \
        tzdata=2025b-r0 \
        zip=3.0-r13 \
        ssmtp=2.64-r22 \
        ca-certificates=20250911-r0 \
        docker-cli=28.3.3-r3 \
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
