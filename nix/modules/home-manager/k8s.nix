{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kustomize
  ];

  programs.k9s.enable = true;
}
