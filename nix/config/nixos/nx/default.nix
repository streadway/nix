{
  inputs,
  ...
}:
{
  system = "x86_64-linux";
  specialArgs = { inherit inputs; };

  modules = [
    inputs.home-manager.nixosModules.home-manager
    ../../../modules/shared/substituters.nix
    ./configuration.nix
    {
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.sean.imports = [ ../../../modules/home-manager/full.nix ];
    }
  ];
}
