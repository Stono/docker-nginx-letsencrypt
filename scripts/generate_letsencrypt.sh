#!/bin/bash
set +e
source /usr/local/bin/nginx_common.sh
FQDN=$1
if [ "$FQDN" = "" ]; then
  echo "No FQDN supplied"
  exit 1
fi

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
