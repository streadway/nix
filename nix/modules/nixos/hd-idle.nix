{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.hd-idle;
in
{
  options.services.hd-idle = {
    enable = mkEnableOption "hd-idle disk spindown service";

    package = mkPackageOption pkgs "hd-idle" { };

    args = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "-i"
        "0"
        "-c"
        "ata"
        "-s"
        "1"
        "-a"
        "/dev/disk/by-uuid/01234567-89ab-cdef-0123-456789abcdef"
        "-i"
        "1800"
      ];
      description = ''
        Command-line arguments passed to `hd-idle`.

        Upstream configures per-device timers with flags such as `-a` and `-i`.
        For example, `-i 0 -c ata -s 1 -a /dev/disk/by-uuid/... -i 1800`
        disables the default timeout, uses ATA spindown commands, resolves the
        symlink at runtime, and spins the selected disk down after 30 minutes.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.hd-idle = {
      description = "hd-idle disk spindown daemon";
      after = [ "local-fs.target" ];
      wants = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} ${escapeShellArgs cfg.args}";
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
