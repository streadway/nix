{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    cloc
    graphviz
    gnumake
    pv
    shellcheck
    tree
    watch
    xz
    yq
  ];

  programs.jq.enable = true;
}
