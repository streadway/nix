# Pi Jellyfin Discovery Design

## Goal

Make the Raspberry Pi's Jellyfin server discoverable across the local network for both Bonjour-aware devices and DLNA/UPnP clients such as a Samsung The Frame TV.

## Design

Use two complementary discovery mechanisms:

1. Keep Jellyfin's built-in LAN auto-discovery on UDP 7359 and explicitly publish the HTTP endpoint over Avahi/mDNS so the server is visible as a named network service on the LAN.
2. Install the official Jellyfin DLNA plugin declaratively so Jellyfin also advertises itself as a DLNA/UPnP media server over SSDP on UDP 1900.

The Avahi advertisement belongs to the Pi's network-discovery boundary. The DLNA plugin belongs to the media-server boundary and should be pinned to a known plugin version in Nix so rebuilds remain reproducible.

## Implementation Notes

- Add an Avahi service definition for Jellyfin's HTTP port `8096`.
- Pin the official Jellyfin DLNA plugin zip in Nix and mount it into Jellyfin's plugin directory through a deterministic symlink created before service start.
- Trigger a Jellyfin restart when the pinned plugin artifact changes.

## Verification

- `avahi-daemon` publishes a Jellyfin service entry.
- Jellyfin listens on UDP `7359` and UDP `1900`.
- Jellyfin logs show the DLNA plugin loading successfully.
- The server remains reachable at `http://192.168.178.2:8096`.
