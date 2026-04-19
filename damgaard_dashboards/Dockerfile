ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8

RUN apk add --no-cache nginx jq

# The build/ directory is baked in at image-build time. See scripts/build-addon.sh
# at the repo root, which runs `npm run build` and stages addon/rootfs/app/.
COPY rootfs /

RUN chmod a+x /run.sh \
    && mkdir -p /var/log/nginx /var/lib/nginx/tmp /run/nginx

EXPOSE 8099

CMD ["/run.sh"]
