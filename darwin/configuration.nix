# vim: ts=2 sw=2 et

{ pkgs, config, nixvim, vars, ... }:

let
in
{
  imports = [
    ../modules/nvim.nix
  ];

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

  users.users.${vars.user} = {
    home = "/Users/${vars.user}";
    shell = pkgs.fish;
  };

  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = [
      pkgs.mkalias
    ];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  fonts.packages = [
    (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  programs.fish.enable = true;

  home-manager.users.${vars.user} = import ../home.nix;

  services.nix-daemon.enable = true;

  system.stateVersion = 5;
}
