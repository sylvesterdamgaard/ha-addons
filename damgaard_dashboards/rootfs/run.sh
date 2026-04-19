#!/usr/bin/env sh
# Boot trace + self-diagnostic: everything stdout/stderr also tees to
# /data/run.log (persisted across restarts). If anything exits non-zero
# we ship the tail of the log to HA Core as a persistent notification
# so `curl /api/states/persistent_notification.*` can see the crash.

CONFIG_PATH=/data/options.json
APP_DIR=/app
LOG=/data/run.log

# Reset the log on every boot so we only ship the latest attempt.
: >"$LOG"

fail_and_notify() {
	local code=$1
	tail -c 3000 "$LOG" > /tmp/log_tail
	# Escape backslashes and quotes for JSON.
	payload=$(jq -Rs . < /tmp/log_tail 2>/dev/null || echo '""')
	if [ -n "$HA_URL" ] && [ -n "$HA_TOKEN" ]; then
		curl -fsS -m 10 -X POST \
			-H "Authorization: Bearer $HA_TOKEN" \
			-H "Content-Type: application/json" \
			-d "{\"title\": \"damgaard_dashboards boot failed\", \"message\": $payload, \"notification_id\": \"damgaard_boot\"}" \
			"$HA_URL/api/services/persistent_notification/create" \
			>>"$LOG" 2>&1 || true
	fi
	exit "$code"
}

# Redirect everything to both console and log.
exec > >(tee -a "$LOG") 2>&1
set -x

echo "[boot] $(date -u +%FT%TZ)"

HA_URL=$(jq -r '.ha_url // empty' "$CONFIG_PATH" 2>/dev/null || true)
HA_TOKEN=$(jq -r '.ha_token // empty' "$CONFIG_PATH" 2>/dev/null || true)

if [ -z "$HA_URL" ] || [ -z "$HA_TOKEN" ]; then
	echo "ERROR: ha_url and ha_token must be configured in the add-on options."
	fail_and_notify 1
fi

# /run and /var/log are tmpfs — create nginx's runtime dirs fresh each boot.
mkdir -p /run/nginx /var/log/nginx /var/lib/nginx/tmp /var/lib/nginx/logs || fail_and_notify 2
ls -la /app | head -20
ls -la /etc/nginx/

# Generate runtime config the SPA fetches before connecting.
cat >"$APP_DIR/config.json" <<EOF
{
  "ha_url": "$HA_URL",
  "ha_token": "$HA_TOKEN"
}
EOF
chmod 644 "$APP_DIR/config.json" || fail_and_notify 3

# Validate nginx config before starting.
nginx -t -c /etc/nginx/nginx.conf || fail_and_notify 4

echo "[ready] Damgaard Dashboards serving $APP_DIR on :8099"

# Trap any unexpected exit from nginx and push diagnostics.
trap 'fail_and_notify $?' EXIT

exec nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
