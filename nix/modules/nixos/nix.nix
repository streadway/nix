{
  pkgs,
  ...
}:
{
  nix = {
    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";

      download-buffer-size = 524288000; # 500 MiB

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
