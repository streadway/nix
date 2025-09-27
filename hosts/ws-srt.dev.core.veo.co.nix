{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    ../modules/nix.nix
    ../modules/cuda.nix
    ../modules/docker-server.nix
    ../modules/ssh-idle-shutdown.nix
  ];

  users.users.sean = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoDCPzWaZ2g6eVgPUfVHWnpz67VO7GsKL9gxFuqLYJL srt.veo.local"
    ];
  };

  users.users.noverby = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOachAYzBH8Qaorvbck99Fw+v6md3BeVtfL5PJ/byv4C niclas@overby.me"
    ];
  };

  services.sshIdleShutdown = {
    enable = true;
    idleMinutes = 300;
  };

  programs.fish.enable = true;
  programs.direnv.enable = true;
  programs.nix-ld.enable = true; # needed for generic python executables like ruff

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.05";
}
