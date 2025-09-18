{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    ruff
    python3
    basedpyright
  ];

  programs.uv.enable = true;
  programs.poetry.enable = true;
}
