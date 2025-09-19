{ pkgs, config, inputs, system, ... }:

{
  nix = {
    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";
    };

    gc = {
      automatic = true;
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
  ];
}
