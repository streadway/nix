# Pi Media Ext4 Reformat Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reformat the Pi's attached Seagate USB media partition from exfat to ext4 and update the NixOS config so `/mnt/media` remounts correctly after rebuild and reboot.

**Architecture:** Perform the destructive disk work directly on the Pi against the stable USB by-id partition path so only the intended external drive is touched. After formatting, update the Pi NixOS config to mount the new ext4 filesystem using its new UUID while preserving the existing automount behavior and Jellyfin access model.

**Tech Stack:** NixOS, systemd automount, ext4, `mkfs.ext4`, `nixos-rebuild`

---

### Task 1: Reformat the USB media partition safely

**Files:**
- Modify: `nix/config/nixos/pi/configuration.nix`
- Create: `docs/superpowers/plans/2026-04-03-pi-media-ext4-reformat.md`

- [ ] Confirm the target device is `/dev/disk/by-id/usb-Seagate_BUP_Ultra_Touch_00000000NAB213QY-0:0-part1`.
- [ ] Stop `jellyfin.service` so nothing scans or reads `/mnt/media`.
- [ ] Stop `mnt-media.automount` and unmount `/mnt/media`.
- [ ] Run `mkfs.ext4 -F -L media` against the USB partition only.
- [ ] Capture the new ext4 UUID with `blkid`.

### Task 2: Update the Pi configuration for ext4

**Files:**
- Modify: `nix/config/nixos/pi/configuration.nix`

- [ ] Remove the exfat-specific `boot.supportedFilesystems` setting.
- [ ] Change `/mnt/media` to use the new ext4 UUID.
- [ ] Replace exfat-only mount options with ext4-safe options while keeping automount behavior.
- [ ] Keep Jellyfin’s `media` group access intact.

### Task 3: Apply and verify the new system state

**Files:**
- Modify: `nix/config/nixos/pi/configuration.nix`

- [ ] Evaluate `nixosConfigurations.pi` locally.
- [ ] Run `nixos-rebuild switch` against `192.168.178.2`.
- [ ] Verify `jellyfin.service` is active again.
- [ ] Verify `/mnt/media` mounts as ext4 after access.
- [ ] Verify the USB partition UUID in the live system matches the config.
