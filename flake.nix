{
  description = "Sean's Nix configurations";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    schpet-tap = {
      url = "github:schpet/homebrew-tap";
      flake = false;
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      nixos-raspberrypi,
      ...
    }:
    {
      darwinConfigurations.veo = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./_hosts/veo
        ];
      };

      nixosConfigurations = {
        nx = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./_hosts/nx
          ];
        };

        pi = nixos-raspberrypi.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            nixos-raspberrypi = inputs.nixos-raspberrypi;
          };
          modules = [
            inputs.nixos-raspberrypi.nixosModules.sd-image
            ./_hosts/pi
          ];
        };

        ws-srt = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./_hosts/ws-srt
          ];
        };

        wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./_hosts/wsl
          ];
        };
      };
    };
}
