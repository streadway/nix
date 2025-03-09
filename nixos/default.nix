{ inputs, nixpkgs, nixpkgs-stable, nixos-wsl, home-manager, nixvim, vars, ... }:

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
  wsl = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs nixpkgs nixpkgs-stable vars; };
    modules = [
      ./configuration.nix
      nixvim.nixosModules.nixvim
      nixos-wsl.nixosModules.default
      {
        system.stateVersion = "24.05";
        wsl.enable = true;
        wsl.defaultUser = "${vars.user}";
      }
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }

    ];
  };

}
	
        
