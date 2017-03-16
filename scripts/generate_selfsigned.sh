#!/bin/bashi
source /usr/local/bin/nginx_common.sh
FQDN=$1
if [ "$FQDN" = "" ]; then
  echo "No FQDN supplied"
  exit 1
fi

mkdir -p /mnt/live/$FQDN
cd /mnt/live/$FQDN

if [ -f "fullchain.pem" ]; then
  info "A certificate already exists for $FQDN, skipping self signed generation."
else
  info "Generating self signed certificate for $FQDN"
  openssl req \
    -new \
    -newkey rsa:2048 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=UK/ST=SelfSigned/L=UK/O=SelfSigned/CN=$FQDN" \
    -keyout key.pem \
    -out fullchain.pem
fi
