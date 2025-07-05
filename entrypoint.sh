#!/usr/bin/env sh
set -eu

envsubst '$$SERVER_NAME $$PREFIX' \
  < /etc/nginx/nginx.conf.template \
  > /usr/local/openresty/nginx/conf/nginx.conf
exec "$@"