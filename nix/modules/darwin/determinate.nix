{
  pkgs,
  ...
}:
{
  nix.enable = false;
  determinateNix.enable = true;

  environment.systemPackages = with pkgs; [
    vim
  ];
}
