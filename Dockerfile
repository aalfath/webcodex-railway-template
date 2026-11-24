# WebCodex Server for Railway.
# Official multi-arch image, pinned by release tag and index digest
# (digest from upstream's webcodex-server-image.json release asset for v0.5.1).
FROM ghcr.io/yyjeqhc/webcodex-server:0.5.1@sha256:bb77ba605ef7a3f5a7fbad36018d556126cd0691d2b00dd39f3aedd31b0fac2e

# The upstream image runs as the unprivileged `webcodex` user, but Railway
# mounts volumes owned by root. The start script fixes ownership of the data
# volume as root and then drops to `webcodex` with setpriv (util-linux).
USER root
COPY --chmod=0755 start.sh /usr/local/bin/webcodex-railway-start

ENV WEBCODEX_DATA=/var/lib/webcodex \
    RUST_LOG=info

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/webcodex-railway-start"]
