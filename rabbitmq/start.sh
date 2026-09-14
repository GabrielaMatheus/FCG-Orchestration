#!/bin/sh
set -eu
: "${RABBITMQ_DEFAULT_USER:?User is required}"
: "${RABBITMQ_DEFAULT_PASS:?Password is required}"
case "$RABBITMQ_DEFAULT_USER" in
  *[!a-zA-Z0-9_.-]*|'') echo 'Invalid RabbitMQ username' >&2; exit 1 ;;
esac
hash=$(rabbitmqctl -q hash_password "$RABBITMQ_DEFAULT_PASS")
sed -e "s#FCG_RABBIT_USER#$RABBITMQ_DEFAULT_USER#g" -e "s#FCG_RABBIT_HASH#$hash#g" /bootstrap/definitions.json > /tmp/fcg-definitions.json
chmod 644 /tmp/fcg-definitions.json
exec /usr/local/bin/docker-entrypoint.sh rabbitmq-server
