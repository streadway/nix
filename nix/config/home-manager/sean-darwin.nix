{
  inputs,
  ...
}:
{
  system = "aarch64-darwin";
  extraSpecialArgs = { inherit inputs; };

  modules = [
    ../../modules/home-manager/full.nix
  ];
}
