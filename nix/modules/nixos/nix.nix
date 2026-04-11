{
  pkgs,
  ...
}:
{
  nix = {
    package = pkgs.lixPackageSets.stable.lix;

    settings = {
      experimental-features = "nix-command flakes";

      trusted-users = [
        "@wheel"
      ];
    };

    gc = {
      automatic = true;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
  ];
}
