{
  config,
  inputs,
  ...
}:
inputs.nixos-raspberrypi.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    nixos-raspberrypi = inputs.nixos-raspberrypi;
  };

  modules = [
    config.propagationModule
    inputs.nixos-raspberrypi.nixosModules.sd-image
    ../../../modules/shared/substituters.nix
    ./configuration.nix
  ];
}
