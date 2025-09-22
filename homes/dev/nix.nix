{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    nil # lsp
    nixd # lsp
    nixpkgs-fmt
    nixfmt-classic
  ];
}
