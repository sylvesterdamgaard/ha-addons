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

# Generate runtime config the SPA fetches before connecting.
cat >"$APP_DIR/config.json" <<EOF
{
  "ha_url": "$HA_URL",
  "ha_token": "$HA_TOKEN"
}
EOF
chmod 600 "$APP_DIR/config.json"

echo "✅ Damgaard Dashboards serving $APP_DIR on :8099"
exec nginx -g 'daemon off;'
