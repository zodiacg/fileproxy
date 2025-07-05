FROM openresty/openresty:1.27.1.2-0-alpine-fat

RUN apk add --no-cache gettext \
 && opm get ledgetech/lua-resty-http

ENV SERVER_NAME=example.com \
    PREFIX=fp

COPY nginx.conf.template       /etc/nginx/nginx.conf.template
COPY lua/resolve_redirect.lua  /etc/nginx/lua/resolve_redirect.lua
COPY entrypoint.sh      /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV SERVER_NAME PREFIX

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
