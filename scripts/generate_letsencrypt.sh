#!/bin/bash
source /usr/local/bin/nginx_common.sh
set -e

NEW_LE=0
generate_lets_encrypt() {
  set +e
  info "Running simp_le letsencrypt for $FQDN"
  mkdir -p /mnt/live/$FQDN
  cd /mnt/live/$FQDN
  simp_le \
    --email $LETSENCRYPT_EMAIL \
    -f account_key.json \
    -f fullchain.pem \
    -f key.pem \
    -d $FQDN \
    --default_root /usr/share/nginx/html \
    --tos_sha256 6373439b9f29d67a5cd4d18cbc7f264809342dbf21cb2ba2fc7588df987a6221
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    NEW_LE=1
  fi
  set -e
}

for_each_host generate_lets_encrypt
