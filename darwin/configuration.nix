# vim: ts=2 sw=2 et

{ pkgs, config, nixvim, ... }:

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


  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = [
    pkgs.mkalias
    ];
    variables = {
      EDITOR= "nvim";
      VISUAL = "nvim";
    };
  };

  fonts.packages = [
    (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ]; 

  services.nix-daemon.enable = true;

  system.stateVersion = 5;

  programs.fish.enable = true;

  users.users.${vars.user} = {
    home = "/Users/${vars.user}";
    shell = pkgs.fish;
  };
}
