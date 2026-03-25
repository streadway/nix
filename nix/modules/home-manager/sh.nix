{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    cloc
    gnumake
    graphviz
    hyperfine
    pv
    shellcheck
    tree
    watch
    xz
    yq
  ];

  programs.jq.enable = true;
}
