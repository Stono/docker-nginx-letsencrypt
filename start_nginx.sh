#!/bin/bash
function finish {
    echo "Detected SIGTERM, Gracefully Shutting Down..."
    sleep 2
    if kill -s 0 $parent >/dev/null 2>&1; then
        echo "Forwarding SIGTERM to Sub Shell PID: $child..."
        (sleep 0.5; kill -TERM $child >/dev/null 2>&1) &
        wait $parent
        exit_code=$?
        echo "Nginx exited with Exit Code: $exit_code"
        exit $exit_code
    else
        echo "Parent pid not running, usually because of it capturing signals itself.  As a result exit code will be set to 143."
        exit 143
    fi
}
trap finish TERM INT

function generate_self_signed() {
  mkdir -p /etc/letsencrypt/live/$FQDN
  cd /etc/letsencrypt/live/$FQDN

  if [ -f "fullchain.pem" ]; then
    echo A certificate already exists for $FQDN, skipping self signed generation.
  else
    echo Generating self signed certificate for $FQDN
    openssl req \
      -new \
      -newkey rsa:4096 \
      -days 365 \
      -nodes \
      -x509 \
      -subj "/C=UK/ST=Manchester/L=UK/O=ThoughtWorks/CN=$FQDN" \
      -keyout key.pem \
      -out fullchain.pem
  fi
}

generate_lets_encrypt() {
  if [ "$LETSENCRYPT" == "true" ]; then
    echo Running simp_le letsencrypt for $FQDN
    cd /etc/letsencrypt/live/$FQDN
    simp_le \
      --email $LETSENCRYPT_EMAIL \
      -f account_key.json \
      -f fullchain.pem \
      -f key.pem \
      -d $FQDN \
      --default_root /usr/share/nginx/html \
      --tos_sha256 6373439b9f29d67a5cd4d18cbc7f264809342dbf21cb2ba2fc7588df987a6221 
  else
    echo Letsencrypt generation has been skipped.
  fi
}

function write_nginx_config() {
  echo Writing nginx config for $FQDN with an upstream of $UPSTREAM
  NAMESERVER=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
  cp /usr/local/etc/nginx/ssl.default.conf /etc/nginx/conf.d/$FQDN.conf
  sed -i "s/FQDN/$FQDN/g" /etc/nginx/conf.d/$FQDN.conf 
  sed -i "s/UPSTREAMNAME/$UPSTREAMNAME/g" /etc/nginx/conf.d/$FQDN.conf
  sed -i "s/UPSTREAM/$UPSTREAM/g" /etc/nginx/conf.d/$FQDN.conf
  sed -i "s/DEFAULT/$DEFAULT/g" /etc/nginx/conf.d/$FQDN.conf
  sed -i "s/NAMESERVER/$NAMESERVER/g" /etc/nginx/conf.d/$FQDN.conf
  cat /etc/nginx/conf.d/$FQDN.conf 
}

function extract_info() {
  UPSTREAMNAME=$(echo ${arr[0]} | awk '{print tolower($0)}')
  HOST=${arr[$j]}
  HOST=${HOST//\"/}
  IFS=','; SPLIT=($HOST)
  FQDN=${SPLIT[0]}
  UPSTREAM=${SPLIT[1]}
  DEFAULT=${SPLIT[2]}
}

start_nginx() {
  echo Starting Nginx
  /usr/sbin/nginx -c /etc/nginx/nginx.conf & 
  parent=$!
  sleep 2
  echo Nginx started with pid $parent
}

reload_nginx() {
  nginx -s reload
}

read -r -a HOSTS <<< $(export  | grep "HOST_" | awk '{ print $3 }')
for i in "${!HOSTS[@]}"; do
  # Remove null entries
  [ -n "${HOSTS[$i]}" ] || unset "HOSTS[$i]"
done

for i in "${!HOSTS[@]}"; do
  VAR=${HOSTS[$i]}
  IFS='='; arr=($VAR)
  for j in "${!arr[@]}"; do
    if [[ $((j % 2)) == 1 ]]; then
      extract_info
      generate_self_signed
      write_nginx_config
    fi
  done
done

nginx -t
start_nginx

for i in "${!HOSTS[@]}"; do
  VAR=${HOSTS[$i]}
  IFS='='; arr=($VAR)
  for j in "${!arr[@]}"; do
    if [[ $((j % 2)) == 1 ]]; then
      extract_info
      generate_lets_encrypt
    fi
  done
done

reload_nginx
sleep 2
wait $parent
