{
  pkgs,
  config,
  inputs,
  system,
  ...
}: {
  nix.enable = false;
  determinateNix.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
  ];
}
