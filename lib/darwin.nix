{ inputs, nixpkgs, nixpkgs-stable, darwin, home-manager, nixvim, vars, ... }:

let
  systemConfig = system: {
    system = system;
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
  };
in
{
  mkDarwinSystem = { system ? "aarch64-darwin", extraModules ? [] }:
    let
      inherit (systemConfig system) pkgs stable;
    in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs system pkgs stable vars; };
      modules = [
        nixvim.nixDarwinModules.nixvim
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
        ../darwin-configuration.nix
      ] ++ extraModules;
    };
} 
