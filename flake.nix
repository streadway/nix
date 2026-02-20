# vim: set sw=2 ts=2 et
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

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-25.05";
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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      codex-cli-nix,
      nixpkgs,
      nixpkgs-stable,
      nix-darwin,
      home-manager,
      nix-homebrew,
      schpet-tap,
      nixvim,
      nixos-wsl,
      nixos-raspberrypi,
      disko,
    }:
    let
      system.configurationRevision = self.rev or self.dirtyRev or null;
    in
    {
      darwinConfigurations = {
        veo = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            nix-homebrew.darwinModules.nix-homebrew
            ./hosts/srt.veo.local.nix
            nixvim.nixDarwinModules.nixvim
            home-manager.darwinModules.home-manager
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = "sean";
                autoMigrate = true;
                taps = {
                  "schpet/homebrew-tap" = schpet-tap;
                };
                mutableTaps = false;
              };
            }
            (
              { config, ... }:
              {
                homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
              }
            )
            {
              home-manager.users.sean =
                { ... }:
                {
                  imports = [
                    ./homes/sean.nix
                    ./homes/dev/aws.nix
                    ./homes/dev/heroku.nix
                    ./homes/dev/k8s.nix

                    ./homes/dev/py.nix
                    ./homes/dev/rs.nix
                    ./homes/dev/sh.nix
                    ./homes/dev/js.nix
                    ./homes/dev/go.nix
                    ./homes/dev/nix.nix
                  ];
                };
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };
      };

      nixosConfigurations.pi = nixos-raspberrypi.lib.nixosSystem {
        specialArgs = inputs;
        modules = [
          nixos-raspberrypi.nixosModules.sd-image
          ./hosts/pi.local.nix
        ];
      };

      nixosConfigurations.ws-srt = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/ws-srt.dev.core.veo.co.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.sean =
              { ... }:
              {
                imports = [
                  ./homes/sean.nix
                  ./homes/dev/rs.nix

                  ./homes/dev/aws.nix
                  ./homes/dev/heroku.nix
                  ./homes/dev/k8s.nix

                  ./homes/dev/py.nix
                  ./homes/dev/rs.nix
                  ./homes/dev/sh.nix
                  ./homes/dev/js.nix
                  ./homes/dev/nix.nix
                ];
              };
          }
        ];
      };

      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs nixpkgs nixpkgs-stable; };
        modules = [
          ./hosts/wsl.local.nix
          nixvim.nixosModules.nixvim
          nixos-wsl.nixosModules.default
          {
            system.stateVersion = "24.05";
            wsl.enable = true;
            wsl.defaultUser = "sean";
          }
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
}
