#!/bin/bash
source /usr/local/bin/helper_funcs.sh

start_nginx() {
  info "Starting Nginx"
  /usr/sbin/nginx -c /etc/nginx/nginx.conf &
  parent=$!
  sleep 2
  info "Nginx started with pid $parent"
}

reload_nginx() {
  info "Reloading Nginx"
  nginx -s reload
}

test_nginx_config() {
  info "Testing Nginx config"
  nginx -t
}

for_each_host() {
  for varname in ${!HOST_*}
  do
    KEY=${varname}
    VALUE=${!varname}

    UPSTREAMNAME=$(echo $KEY | awk '{print tolower($0)}')
    IFS=','; SPLIT=($VALUE)
    FQDN=${SPLIT[0]}
    UPSTREAM=${SPLIT[1]}
    DEFAULT=${SPLIT[2]}
		TARGETPATH=${SPLIT[3]}	
    echo "$UPSTREAMNAME:"
    echo "  -> FQDN: $FQDN"
    echo "  -> UPSTREAM: $UPSTREAM"
    echo "  -> DEFAULT: $DEFAULT"
    echo "  -> TARGETPATH: $TARGETPATH"
    $1
  done
}
