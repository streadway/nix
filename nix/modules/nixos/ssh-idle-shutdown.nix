{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.sshIdleShutdown;

  ssh-idle-shutdown-script = pkgs.writeShellScript "ssh-idle-shutdown" ''
    idleMinutes=${toString cfg.idleMinutes}

    is_ssh_active() {
        [[ $(${pkgs.iproute2}/bin/ss -H -o state established '( sport = :ssh )' | wc -l) -gt 0 ]]
    }

    is_shutdown_active() {
        ${pkgs.systemd}/bin/shutdown --show 2>&1
    }

    if is_ssh_active; then
        if is_shutdown_active; then
            echo "SSH re-established, cancelling shutdown"
            ${pkgs.systemd}/bin/shutdown -c
        else
            echo "SSH established:"
            who
        fi
    else
        if ! is_shutdown_active; then
            echo "SSH not active, shutting down in $idleMinutes minutes"
            ${pkgs.systemd}/bin/shutdown -h "+$idleMinutes" "No SSH connections"
        else
            echo "SSH not active, shutdown pending"
        fi
    fi
  '';
in
{
  options.services.sshIdleShutdown = {
    enable = mkEnableOption "SSH idle shutdown service";

    idleMinutes = mkOption {
      type = types.int;
      default = 120;
      description = "Number of minutes to wait before shutting down when no SSH connections are active (Linux/NixOS only)";
    };
  };

  config = mkIf cfg.enable {
    # Assert that we're running on a Linux system with systemd
    assertions = [
      {
        assertion = pkgs.stdenv.isLinux;
        message = "ssh-idle-shutdown service requires a Linux system with systemd (NixOS)";
      }
    ];
    systemd.services.ssh-idle-shutdown = {
      description = "SSH Idle Shutdown Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${ssh-idle-shutdown-script}";
        User = "root";
      };
    };

    systemd.timers.ssh-idle-shutdown = {
      description = "SSH Idle Shutdown Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "minutely";
        Persistent = true;
      };
    };
  };
}
