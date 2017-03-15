#!/bin/bash
sleep 2
mkdir -p /mnt/live
mkdir -p /mnt/html

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

function write_nginx_config() {
	info "Writing nginx config for $FQDN with an upstream of $UPSTREAM"
	NAMESERVER=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
	cp /usr/local/etc/nginx/ssl.default.conf /etc/nginx/conf.d/$FQDN.conf
	sed -i "s/FQDN/$FQDN/g" /etc/nginx/conf.d/$FQDN.conf
	sed -i "s/UPSTREAMNAME/$UPSTREAMNAME/g" /etc/nginx/conf.d/$FQDN.conf
	sed -i "s|UPSTREAM|$UPSTREAM|g" /etc/nginx/conf.d/$FQDN.conf
	sed -i "s/DEFAULT/$DEFAULT/g" /etc/nginx/conf.d/$FQDN.conf
	sed -i "s|TARGETPATH|$TARGETPATH|g" /etc/nginx/conf.d/$FQDN.conf
	sed -i "s/NAMESERVER/$NAMESERVER/g" /etc/nginx/conf.d/$FQDN.conf
}

function write_redirect_config() {
	echo Writing nginx redirect config for $FQDN with a redirect of $UPSTREAM
	NAMESERVER=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
	cp /usr/local/etc/nginx/redirect.default.conf /etc/nginx/conf.d/$FQDN.conf
	sed -i "s/FQDN/$FQDN/g" /etc/nginx/conf.d/$FQDN.conf
	sed -i "s/UPSTREAM/$UPSTREAM/g" /etc/nginx/conf.d/$FQDN.conf
	cat /etc/nginx/conf.d/$FQDN.conf
}

do_self_signed() {
	. /usr/local/bin/generate_selfsigned.sh
	if [ "$DEFAULT" = "redirect" ]; then
		write_redirect_config
	else
		write_nginx_config
	fi
}
for_each_host do_self_signed

test_nginx_config
start_nginx

if [ "$LETSENCRYPT" == "true" ]; then
	. /usr/local/bin/generate_letsencrypt.sh
	test_nginx_config
	reload_nginx
else
	info "LetsEncrypt is not enabled."
fi

sleep 2
touch /tmp/ready
wait $parent
