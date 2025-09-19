{ pkgs, config, inputs, system, ... }:

{
  nix = {
    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";

      extra-substituters = [
        "https://nix-community.cachix.org"
      ];

      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      trusted-users = [ "root" "@admin" "@wheel" ];
    };

    gc = {
      automatic = true;
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
  ];
}
