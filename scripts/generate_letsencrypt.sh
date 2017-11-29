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
  --tos_sha256 cc88d8d9517f490191401e7b54e9ffd12a2b9082ec7a1d4cec6101f9f1647e7b 
