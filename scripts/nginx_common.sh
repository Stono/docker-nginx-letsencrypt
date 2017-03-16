#!/bin/bash
source /usr/local/bin/helper_funcs.sh

start_nginx() {
  info "Starting Nginx"
  /usr/sbin/nginx -c /etc/nginx/nginx.conf &
  parent=$!
  sleep 2
  info "Nginx started with pid $parent"
}
