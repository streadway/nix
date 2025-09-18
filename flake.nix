# vim: set sw=2 ts=2 et
{
  description = "Sean's NixOS configurations";

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
      vars = {
        user = "sean";
      };
    in
    {
      darwinConfigurations = {
        veo = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            nixvim.nixDarwinModules.nixvim
            home-manager.darwinModules.home-manager {
              home-manager.users.sean = import ./hosts/veo/home.nix;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
            ./hosts/veo/default.nix
          ];
          # extraModules = [
          #   { nixpkgs.config.allowUnfree = true; }
          #   ./veo.nix
          #   ./modules/nvim.nix
          # ];
        };
      };

      nixosConfigurations = (
        import ./nixos {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs nixpkgs-stable home-manager nixos-wsl nixvim vars;
        }
      );
    };
}
