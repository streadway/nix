# vim: set sw=2 ts=2 et
{
  description = "MacGyvertosh";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-24.05";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, darwin, home-manager, nix-homebrew, nixvim }:
    let
      system.configurationRevision = self.rev or self.dirtyRev or null;
      vars = {
        user = "sean";
      };
      
      # Import the Darwin system builder
      darwinLib = import ./lib/darwin.nix {
        inherit inputs nixpkgs nixpkgs-stable darwin home-manager nixvim vars;
      };
    in
    {
      # Darwin configurations
      darwinConfigurations = {
        veo = darwinLib.mkDarwinSystem {
          system = "aarch64-darwin";
          extraModules = [
            ./veo.nix
          ];
        };
      };
      
      # NixOS configurations can be added here
      nixosConfigurations = {
        # Example:
        # myNixosSystem = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [
        #     ./nixos-configuration.nix
        #   ];
        # };
      };
    };
}
