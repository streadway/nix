# vim: set sw=2 ts=2 et
{
  description = "MacGyvertosh";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nix-homebrew, nixpkgs }:
    let
      system.configurationRevision = self.rev or self.dirtyRev or null;
    in {
    darwinConfigurations."veo" = nix-darwin.lib.darwinSystem {
      modules = [
	./darwin.nix
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.sean = import ./home.nix;
        }
	nix-homebrew.darwinModules.nix-homebrew {
	  nix-homebrew = {
	    enable = true;
	    enableRosetta = true;
	    user = "sean";
	    autoMigrate = true;
	  };
	}
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."veo".pkgs;
  };
}
