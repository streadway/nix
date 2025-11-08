{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    ruff
    python3
    basedpyright # for Zed lsp
  ];

  programs.uv.enable = true;
  programs.poetry.enable = true;
}
