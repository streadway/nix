# vim: set sw=2 ts=2 et
{
  description = "Sean's Nix configurations";

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
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

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, nix-darwin, home-manager, nix-homebrew, nixvim, nixos-wsl }:
    let
      system.configurationRevision = self.rev or self.dirtyRev or null;
    in
    {
      darwinConfigurations = {
        veo = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/srt.veo.local.nix
            nixvim.nixDarwinModules.nixvim
            home-manager.darwinModules.home-manager {
              home-manager.users.sean = { ... }: {
                imports = [
                  ./homes/sean.nix
                  ./homes/dev/aws.nix
                  ./homes/dev/heroku.nix
                  ./homes/dev/k8s.nix

                  ./homes/dev/py.nix
                  ./homes/dev/rs.nix
                  ./homes/dev/sh.nix
                  ./homes/dev/js.nix
                ];
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };
      };

      nixosConfigurations.ws-srt = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/ws-srt.dev.core.veo.co.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.sean = { ... }: {
                imports = [
                  ./homes/sean.nix
                  ./homes/dev/rs.nix
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
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }

        ];
      };
    };
}
