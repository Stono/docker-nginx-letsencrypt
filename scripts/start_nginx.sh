#!/bin/bash
sleep 2
mkdir -p /var/log/nginx
mkdir -p /mnt/live
mkdir -p /mnt/html
chown -R nginx:nginx /var/log/nginx
chown -R nginx:nginx /mnt/live
chown -R nginx:nginx /mnt/html

source /usr/local/bin/nginx_common.sh
set -e

function finish {
	info "Detected SIGTERM, Gracefully Shutting Down..."
	sleep 2
	if kill -s 0 $parent >/dev/null 2>&1; then
		info "Forwarding SIGTERM to Sub Shell PID: $child..."
		(sleep 0.5; kill -TERM $child >/dev/null 2>&1) &
		wait $parent
		exit_code=$?
		info "Nginx exited with Exit Code: $exit_code"
		exit $exit_code
	else
		warn "Parent pid not running, usually because of it capturing signals itself.  As a result exit code will be set to 143."
		exit 143
	fi
}
trap finish TERM INT

start_nginx
if [ ! -f "/config/config.json" ] && [ ! -f "/config/config.js" ]; then
  echo "You must specify /config/config.json or /config/config.js"
  exit 1
fi
node /template/template.js

sleep 2
echo "Nginx setup complete"
touch /tmp/ready
wait $parent
