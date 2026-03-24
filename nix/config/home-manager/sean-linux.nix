{
  inputs,
  ...
}:
{
  system = "x86_64-linux";
  extraSpecialArgs = { inherit inputs; };

  modules = [
    ../../modules/home-manager/minimal.nix
  ];
}
