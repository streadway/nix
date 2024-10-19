{ config, lib, system, pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    enableMan = false;
    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = ",";
      maplocalleader = ",";
    };

    extraPlugins = [
      pkgs.vimPlugins.gruvbox
    ];

    plugins = {
      lightline.enable = true;
      nix.enable = true;
      direnv.enable = true;
      auto-save.enable = true;
      orgmode.enable = true;

      lsp = {
        enable = true;
        servers = {
          pyright.enable = true;
          nixd.enable = true;
        };
      };
    };

    colorschemes.gruvbox.enable = true;

    opts = {
      number = true;

      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;

      autoindent = true;
      smartindent = true;
      smarttab = true;

      cursorline = true;
    };
  };
}
