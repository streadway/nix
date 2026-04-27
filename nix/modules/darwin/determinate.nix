{
  config,
  lib,
  pkgs,
  ...
}:
let
  substituters = [
    "https://nix-community.cachix.org"
    "https://nixos-raspberrypi.cachix.org"
  ];

  trustedPublicKeys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
  ];

  primaryUser = lib.attrByPath [ "system" "primaryUser" ] null config;
in
{
  nix.enable = false;
  determinateNix = {
    enable = true;
    customSettings = {
      extra-substituters = lib.concatStringsSep " " substituters;
      extra-trusted-substituters = lib.concatStringsSep " " substituters;
      extra-trusted-public-keys = lib.concatStringsSep " " trustedPublicKeys;
    }
    // lib.optionalAttrs (primaryUser != null) {
      # Allow the interactive user to opt into flake-provided substituters.
      "extra-trusted-users" = primaryUser;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
  ];
}
