# Nix

This repo is organized around `flakelight`. The top-level [flake.nix](/Users/sean/.config/nix/.workspaces/flakelight-reorg/flake.nix) stays small: it declares inputs, imports local flakelight support modules, and lets flakelight discover configurations and modules from `./nix`.

## Layout

```text
nix/
  config/
    darwin/
      veo/
        default.nix
        configuration.nix
    nixos/
      pi/
      ws-srt/
      wsl/
    home-manager/
      sean-darwin.nix
      sean-linux.nix
  modules/
    flakelight/
      default.nix
      darwin-configurations.nix
      darwin-modules.nix
    darwin/
      determinate.nix
      homebrew.nix
      nixvim.nix
    nixos/
      cuda.nix
      docker-server.nix
      nix.nix
      nixvim.nix
      ssh-idle-shutdown.nix
    home-manager/
      base.nix
      full.nix
      minimal.nix
      aws.nix
      gcp.nix
      go.nix
      heroku.nix
      java.nix
      js.nix
      k8s.nix
      nix.nix
      py.nix
      rs.nix
      sh.nix
    shared/
      nixvim.nix
```

## Discovery

`flake.nix` maps flakelight's outputs onto the repo layout with aliases:

- `nix/config/darwin` -> `darwinConfigurations`
- `nix/config/nixos` -> `nixosConfigurations`
- `nix/config/home-manager` -> `homeConfigurations`
- `nix/modules/darwin` -> `darwinModules`
- `nix/modules/nixos` -> `nixosModules`
- `nix/modules/home-manager` -> `homeModules`

The `nix/modules/flakelight` directory contains local flakelight modules that add Darwin output support in the same style flakelight already provides for NixOS and Home Manager.

## Home Manager Profiles

The old `homes/dev/*` slice is flattened into `nix/modules/home-manager`.

- `base.nix` is the shared user profile.
- `minimal.nix` imports only `base.nix`.
- `full.nix` imports `base.nix` plus the actively used development modules.
- Individual modules like `aws.nix`, `py.nix`, and `rs.nix` remain reusable on their own.

## Commands

Run commands from this directory:

- `darwin-rebuild switch --flake .#veo`
- `sudo nixos-rebuild switch --flake .#ws-srt`
- `sudo nixos-rebuild switch --flake .#wsl`
- `sudo nixos-rebuild switch --flake .#pi`
- `home-manager switch --flake .#sean-darwin`
- `home-manager switch --flake .#sean-linux`
