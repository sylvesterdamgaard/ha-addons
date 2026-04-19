#!/bin/sh
# Boots the dashboard stack:
#  1. Read ha_url + ha_token from /data/options.json.
#  2. Drop runtime config into /app/config.json so the SPA can fetch it.
#  3. Validate nginx config, report progress to sensor.damgaard_boot, exec nginx.
# On any non-zero exit, the trap ships the last 3 KB of trace to the sensor so
# we can inspect failures via /api/states/sensor.damgaard_boot without needing
# supervisor log access.

set -u
CONFIG_PATH=/data/options.json
APP_DIR=/app
LOG=/data/run.log

: >"$LOG"
exec >>"$LOG" 2>&1
set -x

HA_URL=$(jq -r '.ha_url // empty' "$CONFIG_PATH" 2>/dev/null || echo "")
HA_TOKEN=$(jq -r '.ha_token // empty' "$CONFIG_PATH" 2>/dev/null || echo "")

report_state() {
	state=$1
	log_tail=$(tail -c 3000 "$LOG" | jq -Rs . 2>/dev/null || echo '""')
	if [ -n "$HA_URL" ] && [ -n "$HA_TOKEN" ]; then
		curl -fsS -m 10 -X POST \
			-H "Authorization: Bearer $HA_TOKEN" \
			-H "Content-Type: application/json" \
			-d "{\"state\": \"$state\", \"attributes\": {\"friendly_name\": \"Damgaard dashboards boot\", \"log\": $log_tail}}" \
			"$HA_URL/api/states/sensor.damgaard_boot" >/dev/null || true
	fi
}

on_exit() {
	code=$?
	if [ "$code" -ne 0 ]; then
		report_state "failed_exit_$code"
	fi
	exit "$code"
}
trap on_exit EXIT

if [ -z "$HA_URL" ] || [ -z "$HA_TOKEN" ]; then
	echo "ERROR: ha_url and ha_token must be configured in the add-on options."
	exit 1
fi

# /run and /var/log are tmpfs — create nginx's runtime dirs fresh each boot.
mkdir -p /run/nginx /var/log/nginx /var/lib/nginx/tmp /var/lib/nginx/logs

echo "--- /app (first 10 entries) ---"
ls -la /app | head -10
echo "--- nginx -v ---"
nginx -v 2>&1

cat >"$APP_DIR/config.json" <<EOF
{
  "ha_url": "$HA_URL",
  "ha_token": "$HA_TOKEN"
}
EOF
chmod 644 "$APP_DIR/config.json"

nginx -t -c /etc/nginx/nginx.conf

report_state "nginx_starting"

exec nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
