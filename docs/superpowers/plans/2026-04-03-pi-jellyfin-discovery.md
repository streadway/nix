# Pi Jellyfin Discovery Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish Jellyfin on the Pi over mDNS and DLNA so LAN clients and the Samsung TV can discover it automatically.

**Architecture:** Extend the Pi's Avahi configuration with a dedicated Jellyfin service record and pin the official Jellyfin DLNA plugin in Nix. Keep the plugin installation inside Jellyfin's own runtime boundary by creating the plugin symlink from Jellyfin's `preStart` hook and restarting the service when the plugin artifact changes.

**Tech Stack:** NixOS modules, Avahi, Jellyfin, systemd

---

## Chunk 1: Pi discovery configuration

### Task 1: Declare Jellyfin discovery settings

**Files:**
- Modify: `nix/config/nixos/pi/configuration.nix`
- Create: `docs/superpowers/specs/2026-04-03-pi-jellyfin-discovery-design.md`
- Create: `docs/superpowers/plans/2026-04-03-pi-jellyfin-discovery.md`

- [ ] Add a pinned Nix fetch for the official Jellyfin DLNA plugin artifact.
- [ ] Extend `services.avahi` with a Jellyfin HTTP service record.
- [ ] Extend `systemd.services.jellyfin` so the plugin symlink exists before start and Jellyfin restarts when the plugin artifact changes.
- [ ] Evaluate the `.#pi` system locally with `nix eval`.

### Task 2: Apply and verify on the Pi

**Files:**
- Modify: `nix/config/nixos/pi/configuration.nix`

- [ ] Switch the remote Pi with `nix run nixpkgs#nixos-rebuild -- switch --flake 'path:/Users/sean/.config/home#pi' --build-host root@192.168.178.2 --target-host root@192.168.178.2`.
- [ ] Verify Avahi publishes the Jellyfin service entry.
- [ ] Verify Jellyfin listens on UDP `7359` and UDP `1900`.
- [ ] Verify Jellyfin logs show the DLNA plugin loaded.
