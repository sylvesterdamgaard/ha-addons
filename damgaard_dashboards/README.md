# Damgaard Dashboards — Home Assistant Add-on

Serves the SvelteKit static build on port **8099** of your HA host. Configuration (`ha_url`, `ha_token`) is written at container start into `/app/config.json`, which the SPA fetches before opening the WebSocket — so you can rotate tokens without rebuilding the image.

## One-time setup

**1. Build the app and stage it into the add-on:**

```bash
scripts/build-addon.sh
```

This runs `npm run build` and copies `build/` into `addon/rootfs/app/`. Do this every time you want the tablets to see new changes.

**2. Copy the add-on onto your HA host** (one of):

- **SMB share** — drop `addon/` into `\\homeassistant\addons\damgaard_dashboards\`
- **SSH** — `rsync -av addon/ root@homeassistant.local:/addons/damgaard_dashboards/`
- **Samba Add-on + Finder** — copy locally into the `addons` share

**3. Install it in HA:**

- Settings → Add-ons → Add-on Store → ⋮ (top-right) → Check for updates
- "Damgaard Dashboards" appears under "Local add-ons"
- Install → Configuration tab → fill in:
	- `ha_url`: `http://supervisor/core` (if talking to HA from within the add-on) **or** your public URL like `https://xxx.ui.nabu.casa`
	- `ha_token`: long-lived access token from Profile → Security
- Start the add-on.

**4. Point the tablets:**

- Family hub: `http://homeassistant.local:8099/hub`
- Stue: `http://homeassistant.local:8099/room/stue`
- Soveværelse: `http://homeassistant.local:8099/room/sovevaerelse`

Use the LAN hostname so the tablets don't go through Nabu Casa on every state change.

## Updating

When you ship a new version:

```bash
# 1. Bump addon/config.yaml "version"
# 2. Rebuild + re-stage:
scripts/build-addon.sh
# 3. Re-sync to the HA host
# 4. Settings → Add-ons → Damgaard Dashboards → Rebuild (or Update)
```

## Troubleshooting

- **Add-on won't start** → check the add-on log. Most common cause: `ha_url` / `ha_token` empty in options.
- **Tablet shows "OFFLINE"** → the container is up but the token is wrong, expired, or HA is unreachable from the tablet's network. Hit `http://homeassistant.local:8099/hub` on your laptop first to triage.
- **Changes don't show up after rebuild** → Fully Kiosk caches aggressively; on the tablet pull from the top to refresh, or use Reload Page from the kiosk menu.

## Security note

`ha_token` is a long-lived token. Don't expose port 8099 outside your LAN — and don't put this add-on behind Nabu Casa ingress unless you really want that token travelling through the cloud. The add-on explicitly binds 8099 on the host (not ingress).
