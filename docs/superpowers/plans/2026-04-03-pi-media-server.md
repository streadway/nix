## Goal

Turn the Raspberry Pi into a Jellyfin media server backed by the attached exfat USB disk without reformatting it.

## Decisions

- Keep the existing `exfat` filesystem on the Seagate USB drive.
- Mount the drive at `/mnt/media` via its filesystem UUID so it comes back consistently after reboot.
- Grant Jellyfin access through a dedicated `media` group rather than opening the mount to every local user.
- Use `hd-idle` against the drive's stable `/dev/disk/by-id/...` path so the disk can spin down after inactivity and wake on demand.

## Verification

- `nix eval --raw 'path:/Users/sean/.config/home#nixosConfigurations.pi.config.system.build.toplevel.drvPath'`
- `nix run nixpkgs#nixos-rebuild -- switch --flake 'path:/Users/sean/.config/home#pi' --build-host root@192.168.178.2 --target-host root@192.168.178.2`
- `ssh -o BatchMode=yes root@192.168.178.2 findmnt /mnt/media`
- `ssh -o BatchMode=yes root@192.168.178.2 systemctl status jellyfin --no-pager`
- `ssh -o BatchMode=yes root@192.168.178.2 systemctl status hd-idle-media --no-pager`
