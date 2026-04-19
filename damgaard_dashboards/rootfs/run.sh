#!/bin/sh
# Probe: verify run.sh executes at all (plain alpine this time, no s6-overlay).
CONFIG_PATH=/data/options.json
HA_URL=$(jq -r '.ha_url // empty' "$CONFIG_PATH" 2>/dev/null || echo "")
HA_TOKEN=$(jq -r '.ha_token // empty' "$CONFIG_PATH" 2>/dev/null || echo "")

curl -sS -m 10 -X POST \
	-H "Authorization: Bearer $HA_TOKEN" \
	-H "Content-Type: application/json" \
	-d '{"state":"run_sh_executed","attributes":{"friendly_name":"Damgaard boot diagnostic","base":"alpine"}}' \
	"$HA_URL/api/states/sensor.damgaard_boot" >/dev/null

echo "run.sh reached curl call"
sleep 3600
