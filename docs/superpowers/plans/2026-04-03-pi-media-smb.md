# Pi Media SMB Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/mnt/media` writable over SMB to anonymous clients on the local LAN without breaking Jellyfin access.

**Architecture:** Add a dedicated Samba guest writer account, export a single LAN-restricted guest share, and reapply mount-root permissions when `/mnt/media` activates. Keep Jellyfin access on the existing `media` group boundary so SMB and playback use the same ownership model.

**Tech Stack:** NixOS, Samba, systemd mount hooks, Jellyfin

---

### Task 1: Add the SMB share and ownership model

**Files:**
- Create: `docs/superpowers/specs/2026-04-03-pi-media-smb-design.md`
- Create: `docs/superpowers/plans/2026-04-03-pi-media-smb.md`
- Modify: `nix/config/nixos/pi/configuration.nix`

- [ ] Add a dedicated `media-share` system user in the `media` group.
- [ ] Add a oneshot service that reapplies `root:media` and `2775` to `/mnt/media` when the mount activates.
- [ ] Enable Samba with a single `media` share rooted at `/mnt/media`.
- [ ] Restrict guest SMB access to `192.168.178.*`, loopback, and localhost only.

### Task 2: Apply and verify the Pi configuration

**Files:**
- Modify: `nix/config/nixos/pi/configuration.nix`

- [ ] Evaluate `nixosConfigurations.pi` locally.
- [ ] Switch the remote `.#pi` system.
- [ ] Verify `samba-smbd`, `nmbd`, `jellyfin`, and `mnt-media.automount` are active.
- [ ] Verify the exported share is configured for guest write access with `testparm -s`.
- [ ] Verify `/mnt/media` is owned `root:media` with mode `2775`.
