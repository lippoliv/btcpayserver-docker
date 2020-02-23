#!/bin/bash

set -e

: "${BTCPAYGEN_DOCKER_IMAGE:=btcpayserver/docker-compose-generator}"
if [ "$BTCPAYGEN_DOCKER_IMAGE" == "btcpayserver/docker-compose-generator:local" ]
then
    docker build docker-compose-generator -f docker-compose-generator/linuxamd64.Dockerfile --tag $BTCPAYGEN_DOCKER_IMAGE
else
    set +e
    docker pull $BTCPAYGEN_DOCKER_IMAGE
    docker rmi $(docker images btcpayserver/docker-compose-generator --format "{{.Tag}};{{.ID}}" | grep "^<none>" | cut -f2 -d ';') > /dev/null 2>&1
    set -e
fi

# This script will run docker-compose-generator in a container to generate the yml files
docker run -v "$(pwd)/Generated:/app/Generated" \
           -v "$(pwd)/docker-compose-generator/docker-fragments:/app/docker-fragments" \
           -v "$(pwd)/docker-compose-generator/crypto-definitions.json:/app/crypto-definitions.json" \
           -e "BTCPAY_HOST=pay.lipperts-web.de" \
           -e "LIGHTNING_ALIAS=LWLN01" \
           -e "BTCPAYGEN_CRYPTO1=btc" \
           -e "BTCPAYGEN_REVERSEPROXY=" \
           -e "BTCPAYGEN_ADDITIONAL_FRAGMENTS=" \
           -e "BTCPAYGEN_LIGHTNING=lnd" \
           -e "BTCPAYGEN_SUBNAME=" \
           -e "BTCPAYGEN_EXCLUDE_FRAGMENTS=opt-add-tor" \
           -e "EPS_XPUB=$EPS_XPUB" \
           --rm $BTCPAYGEN_DOCKER_IMAGE

if [ "$BTCPAYGEN_REVERSEPROXY" == "nginx" ]; then
    cp Production/nginx.tmpl Generated/nginx.tmpl
fi

[[ -f "Generated/pull-images.sh" ]] && chmod +x Generated/pull-images.sh
[[ -f "Generated/save-images.sh" ]] && chmod +x Generated/save-images.sh

if [ "$BTCPAYGEN_REVERSEPROXY" == "traefik" ]; then
    cp Traefik/traefik.toml Generated/traefik.toml
    :> Generated/acme.json
    chmod 600 Generated/acme.json
fi
