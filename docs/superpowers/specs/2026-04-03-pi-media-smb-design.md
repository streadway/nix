# Pi Media SMB Design

## Goal

Expose `/mnt/media` from the Pi as a guest-accessible SMB share for the local `192.168.178.*` LAN while preserving Jellyfin readability.

## Design

- Enable Samba on the Pi and publish a single `media` share rooted at `/mnt/media`.
- Restrict access to the local LAN and loopback with Samba `hosts allow` / `hosts deny` rules.
- Use a dedicated system account, `media-share`, for guest SMB writes instead of writing as `root` or mutating `nobody`.
- Keep the existing `media` group as the shared read boundary for Jellyfin.
- Reapply `root:media` and `2775` on the mounted filesystem root when `/mnt/media` mounts so guest uploads stay group-readable for Jellyfin.

## Verification

- `nix eval --raw 'path:/Users/sean/.config/home#nixosConfigurations.pi.config.system.build.toplevel.drvPath'`
- `nix run nixpkgs#nixos-rebuild -- switch --flake 'path:/Users/sean/.config/home#pi' --build-host root@192.168.178.2 --target-host root@192.168.178.2`
- `ssh -o BatchMode=yes root@192.168.178.2 'systemctl is-active samba-smbd.service nmbd.service jellyfin.service mnt-media.automount'`
- `ssh -o BatchMode=yes root@192.168.178.2 'testparm -s'`
- `ssh -o BatchMode=yes root@192.168.178.2 'stat -c \"%U %G %a\" /mnt/media'`
