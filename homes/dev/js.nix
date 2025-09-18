{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    nodejs
    typescript
  ];
}
