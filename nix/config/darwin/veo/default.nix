{
  inputs,
  ...
}:
{
  system = "aarch64-darwin";
  specialArgs = { inherit inputs; };

  modules = [
    inputs.determinate.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.nixvim.nixDarwinModules.nixvim
    ./configuration.nix
    {
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.sean.imports = [
        ../../../modules/home-manager/full.nix
      ];
    }
  ];
}
