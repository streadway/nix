{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    nil # lsp
    nixd # lsp
    nixfmt
    alejandra
  ];
}
