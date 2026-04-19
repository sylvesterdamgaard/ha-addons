ARG BUILD_FROM
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8

RUN apk add --no-cache nginx jq curl \
    && rm -f /etc/nginx/http.d/default.conf

COPY rootfs /

RUN chmod a+x /run.sh \
    && mkdir -p /var/log/nginx /var/lib/nginx/tmp /run/nginx

EXPOSE 8099

CMD ["/run.sh"]
