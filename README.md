# Nix

This repo uses direct flake outputs. The top-level [flake.nix](/Users/sean/.config/home/flake.nix) declares inputs and wires each host to a single `_hosts/<name>/default.nix` module.

## Hosts

Each host owns its system configuration and Home Manager configuration in one file:

- `_hosts/veo/default.nix`
- `_hosts/nx/default.nix`
- `_hosts/pi/default.nix`
- `_hosts/ws-srt/default.nix`
- `_hosts/wsl/default.nix`

## Commands

Run commands from this directory:

- `darwin-rebuild switch --flake .#veo`
- `sudo nixos-rebuild switch --flake .#ws-srt`
- `sudo nixos-rebuild switch --flake .#wsl`
- `sudo nixos-rebuild switch --flake .#pi`
- `sudo nixos-rebuild switch --flake .#nx`
