# Damgaard Home Assistant Add-ons

Private, one-family add-on repository.

## Add to your Home Assistant

Settings → Add-ons → Add-on Store → ⋮ (top-right) → Repositories →

```
https://github.com/sylvesterdamgaard/ha-addons
```

Click **Add**. The add-ons below then appear at the bottom of the Add-on Store under "Damgaard Home Assistant Add-ons".

## Add-ons

### 🏠 Damgaard Dashboards

Custom SvelteKit dashboards for 12" Acer Android tablets — one family hub + per-room views. Connects to Home Assistant via WebSocket, serves the static build on port 8099.

After install:
1. Configuration tab → set `ha_url` (e.g. `https://xxx.ui.nabu.casa`) and `ha_token` (long-lived access token)
2. Start the add-on
3. Open `http://homeassistant.local:8099/hub` on the family tablet, `/room/stue` on the Stue tablet, etc.

See `damgaard_dashboards/README.md` for details.
