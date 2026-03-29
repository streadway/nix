{ pkgs, ... }:
{
  hardware.keyboard.qmk.enable = true;
  environment.systemPackages = with pkgs; [
    qmk
    via
  ];
  services.udev.packages = with pkgs; [
    vial
    via
  ];
}
