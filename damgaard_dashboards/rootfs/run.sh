#!/usr/bin/env sh
# Self-diagnostic boot: traces to /data/run.log (persisted) and, on
# non-zero exit, ships the tail of the log to HA Core as a persistent
# notification. That way /api/states/persistent_notification.damgaard_boot
# shows the crash from outside the supervisor.

set -u
CONFIG_PATH=/data/options.json
APP_DIR=/app
LOG=/data/run.log

: >"$LOG"
exec >>"$LOG" 2>&1
set -x

echo "[boot] $(date -u +%FT%TZ)"

HA_URL=$(jq -r '.ha_url // empty' "$CONFIG_PATH" 2>/dev/null || echo "")
HA_TOKEN=$(jq -r '.ha_token // empty' "$CONFIG_PATH" 2>/dev/null || echo "")

notify_and_exit() {
	code=${1:-1}
	tail=$(tail -c 3500 "$LOG")
	tail_json=$(printf '%s' "$tail" | jq -Rs . 2>/dev/null || echo '""')
	if [ -n "$HA_URL" ] && [ -n "$HA_TOKEN" ]; then
		curl -fsS -m 10 -X POST \
			-H "Authorization: Bearer $HA_TOKEN" \
			-H "Content-Type: application/json" \
			-d "{\"state\": \"boot_failed_exit_$code\", \"attributes\": {\"friendly_name\": \"Damgaard dashboards boot log\", \"log\": $tail_json}}" \
			"$HA_URL/api/states/sensor.damgaard_boot" || true
	fi
	exit "$code"
}

notify_running() {
	if [ -n "$HA_URL" ] && [ -n "$HA_TOKEN" ]; then
		curl -fsS -m 10 -X POST \
			-H "Authorization: Bearer $HA_TOKEN" \
			-H "Content-Type: application/json" \
			-d '{"state": "running", "attributes": {"friendly_name": "Damgaard dashboards boot log", "log": "nginx started ok"}}' \
			"$HA_URL/api/states/sensor.damgaard_boot" || true
	fi
}

trap 'notify_and_exit $?' EXIT

if [ -z "$HA_URL" ] || [ -z "$HA_TOKEN" ]; then
	echo "ERROR: ha_url and ha_token must be configured in the add-on options."
	exit 1
fi

# /run and /var/log are tmpfs; make nginx's runtime dirs fresh each boot.
mkdir -p /run/nginx /var/log/nginx /var/lib/nginx/tmp /var/lib/nginx/logs

echo "--- /app ---"
ls -la /app 2>&1 | head -20
echo "--- /etc/nginx ---"
ls -la /etc/nginx 2>&1
echo "--- nginx -v ---"
nginx -v 2>&1

# Generate runtime config the SPA fetches before connecting.
cat >"$APP_DIR/config.json" <<EOF
{
  "ha_url": "$HA_URL",
  "ha_token": "$HA_TOKEN"
}
EOF
chmod 644 "$APP_DIR/config.json"

# Validate nginx config before starting so errors surface with a readable line.
nginx -t -c /etc/nginx/nginx.conf

echo "[ready] Damgaard Dashboards serving $APP_DIR on :8099"
notify_running

exec nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
