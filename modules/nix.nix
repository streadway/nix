{ pkgs, config, inputs, system, ... }:

{
  nix = {
    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";
    };

    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";

    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };
}
