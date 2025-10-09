{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.awscli = {
    enable = true;
    package = pkgs.awscli.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  };

  programs.granted = {
    enable = true;
    enableFishIntegration = true;
  };
}
