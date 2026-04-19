#!/usr/bin/env sh
set -e

CONFIG_PATH=/data/options.json
APP_DIR=/app

HA_URL=$(jq -r '.ha_url // empty' "$CONFIG_PATH")
HA_TOKEN=$(jq -r '.ha_token // empty' "$CONFIG_PATH")

if [ -z "$HA_URL" ] || [ -z "$HA_TOKEN" ]; then
	echo "❌ ha_url and ha_token must be configured in the add-on options." >&2
	exit 1
fi

# /run and /var/log are tmpfs — create nginx's runtime dirs fresh each boot.
mkdir -p /run/nginx /var/log/nginx /var/lib/nginx/tmp /var/lib/nginx/logs

# Generate runtime config the SPA fetches before connecting.
cat >"$APP_DIR/config.json" <<EOF
{
  "ha_url": "$HA_URL",
  "ha_token": "$HA_TOKEN"
}
EOF
chmod 644 "$APP_DIR/config.json"

echo "✅ Damgaard Dashboards serving $APP_DIR on :8099"
exec nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
