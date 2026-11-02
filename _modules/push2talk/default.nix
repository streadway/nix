{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    escapeShellArg
    escapeShellArgs
    getExe
    makeBinPath
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.push2talk;

  pkg = pkgs.rustPlatform.buildRustPackage {
    pname = "push2talk";
    version = "0.1.0";
    src = ./.;
    cargoLock.lockFile = ./Cargo.lock;
    nativeBuildInputs = [pkgs.makeBinaryWrapper];
    buildInputs = [pkgs.wireplumber];
    postFixup = ''
      wrapProgram $out/bin/push2talk \
        --prefix PATH : ${makeBinPath [pkgs.wireplumber]}
    '';
    meta.mainProgram = "push2talk";
  };
in {
  options.services.push2talk = {
    enable = mkEnableOption "Wayland/PipeWire push-to-talk microphone mute/unmute service";

    package = mkOption {
      type = types.package;
      default = pkg;
      description = "The push2talk package to use.";
    };

    device = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to the Linux evdev input device to watch, or null/\"all\" to watch all mice/matching devices.";
    };

    keyCode = mkOption {
      type = types.str;
      description = "Linux input event key/button name or code to listen for (e.g., BTN_EXTRA, BTN_SIDE, 0x114).";
    };

    source = mkOption {
      type = types.str;
      default = "@DEFAULT_AUDIO_SOURCE@";
      description = "PipeWire audio source target passed to wpctl set-mute.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    systemd.user.services.push2talk = {
      description = "Wayland/PipeWire Push-to-Talk microphone mute/unmute service";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = [
        "graphical-session.target"
        "wireplumber.service"
      ];
      unitConfig = {
        ConditionGroup = "input";
      };
      serviceConfig = {
        ExecStart = "${getExe cfg.package} ${escapeShellArgs [
          (
            if cfg.device == null
            then "all"
            else cfg.device
          )
          cfg.keyCode
          cfg.source
        ]}";
        ExecStartPost = "-${pkgs.wireplumber}/bin/wpctl set-mute ${escapeShellArg cfg.source} 1";
        ExecStopPost = "-${pkgs.wireplumber}/bin/wpctl set-mute ${escapeShellArg cfg.source} 1";
        Restart = "always";
        RestartSec = "2";
      };
    };
  };
}
