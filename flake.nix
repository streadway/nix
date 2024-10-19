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

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, darwin, home-manager, nix-homebrew, nixvim, nixos-wsl }:
    let
      system.configurationRevision = self.rev or self.dirtyRev or null;
      vars = {
        user = "sean";
      };
    in
    {
      darwinConfigurations = (
        import ./darwin {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs nixpkgs-stable home-manager darwin nixvim vars;
        }
      );

      nixosConfigurations = (
        import ./nixos {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs nixpkgs-stable home-manager nixos-wsl nixvim vars;
        }
      );
    };
}
