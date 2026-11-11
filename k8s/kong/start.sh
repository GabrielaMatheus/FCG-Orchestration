#!/bin/sh
set -eu
: "${JWT_SECRET:?JWT_SECRET is required}"
case "$JWT_SECRET" in
  *[!a-zA-Z0-9_-]*|'') echo 'JWT_SECRET must use letters, digits, _ or -' >&2; exit 1 ;;
esac
test "${#JWT_SECRET}" -ge 32 || { echo 'JWT_SECRET must contain at least 32 characters' >&2; exit 1; }
sed "s/FCG_JWT_SECRET_PLACEHOLDER/$JWT_SECRET/g" /kong/template/kong.yml > /tmp/kong.yml
export KONG_DECLARATIVE_CONFIG=/tmp/kong.yml
exec /docker-entrypoint.sh kong docker-start
