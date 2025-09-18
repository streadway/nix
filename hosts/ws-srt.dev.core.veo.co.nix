{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    ../modules/nix.nix
    ../modules/cuda.nix
    ../modules/docker-server.nix
  ];

  users.users.sean = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  programs.direnv.enable = true;

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.05";
}
