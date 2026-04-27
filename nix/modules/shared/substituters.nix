{
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
in
{
  nix.settings = {
    extra-substituters = substituters;
    extra-trusted-substituters = substituters;
    extra-trusted-public-keys = trustedPublicKeys;
  };
}
