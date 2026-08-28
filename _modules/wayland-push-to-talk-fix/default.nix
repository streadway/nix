{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    escapeShellArgs
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.wayland-push-to-talk-fix;
  pkg = pkgs.callPackage ./package.nix {};

  args =
    lib.optionals cfg.verbose ["-v"]
    ++ lib.optionals (cfg.keyCode != null) ["-k" cfg.keyCode]
    ++ lib.optionals (cfg.keyName != null) ["-n" cfg.keyName]
    ++ cfg.extraArgs
    ++ [cfg.device];
in {
  options.services.wayland-push-to-talk-fix = {
    enable = mkEnableOption "Wayland Push-to-Talk fix for Discord";

    package = mkOption {
      type = types.package;
      default = pkg;
      description = "The wayland-push-to-talk-fix package to use.";
    };

    device = mkOption {
      type = types.str;
      description = "Path to the input device to listen on (e.g., /dev/input/by-id/...).";
      example = "/dev/input/by-id/usb-Razer_Razer_Naga_Epic_Chroma-event-if01";
    };

    keyCode = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Linux input event keycode to listen for (e.g., "KEY_LEFTMETA", "KEY_F1", "BTN_SIDE").
        If unset, defaults to KEY_LEFTMETA.
      '';
    };

    keyName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        X11 keysym or mouse button to send to Discord (e.g., "Super_L", "F13", "MOUSE1").
        If unset, defaults to Super_L.
      '';
    };

    verbose = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable verbose logging.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra arguments to pass to push-to-talk.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    systemd.user.services.wayland-push-to-talk-fix = {
      description = "Wayland Push-to-Talk Fix for Discord";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/push-to-talk ${escapeShellArgs args}";
        Restart = "always";
        RestartSec = "2";
      };
    };
  };
}
