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
