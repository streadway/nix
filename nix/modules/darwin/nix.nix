{
  config,
  lib,
  pkgs,
  ...
}: let
  primaryUser = lib.attrByPath ["system" "primaryUser"] null config;
in {
  nix = {
    enable = true;
    package = pkgs.nix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = lib.mkForce [
        "https://cache.nixos.org/"
      ];

      trusted-public-keys = lib.mkForce [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      trusted-users = lib.mkForce (
        [
          "root"
        ]
        ++ lib.optionals (primaryUser != null) [
          primaryUser
        ]
      );
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    vim
  ];
}
