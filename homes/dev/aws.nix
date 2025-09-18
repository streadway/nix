{ config, lib, pkgs, ... }:
{
  programs.awscli = {
    enable = true;
  };

  programs.granted = {
    enable = true;
    enableFishIntegration = true;
  };
}
