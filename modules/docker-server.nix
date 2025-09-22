{
  config,
  pkgs,
  lib,
  ...
}:

{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      experimental = true;
    };
  };

  # Ensure docker group exists
  users.groups.docker = { };
}
