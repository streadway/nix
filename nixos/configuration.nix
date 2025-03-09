# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, nixvim, vars, ... }:

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
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  environment = {
    systemPackages = [
      pkgs.tzdata
      pkgs.vim
      pkgs.git
      pkgs.fishPlugins.tide
    ];

    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };
  };

  users.users.${vars.user} = {
    home = "/home/${vars.user}";
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  programs.direnv.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };

  home-manager.users.${vars.user} = import ../home.nix;

  system.stateVersion = "24.05";
}
