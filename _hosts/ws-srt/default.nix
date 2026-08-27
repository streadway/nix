{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  sshIdleShutdownCfg = config.services.sshIdleShutdown;

  sshIdleShutdownScript = pkgs.writeShellScript "ssh-idle-shutdown" ''
    idleMinutes=${toString sshIdleShutdownCfg.idleMinutes}

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

  seanHome = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.username = "sean";
    home.homeDirectory =
      if pkgs.stdenv.hostPlatform.isDarwin
      then "/Users/${config.home.username}"
      else "/home/${config.home.username}";
    home.stateVersion = "24.05";

    home.packages = with pkgs; [
      _1password-cli
      act
      bat
      cacert
      claude-code
      cloc
      difftastic
      ffmpeg
      gemini-cli
      google-cloud-sdk
      grafana-loki
      graphviz
      heroku
      htop
      hyperfine
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      jjui
      kubectl
      kustomize
      nil
      nixd
      nixfmt
      alejandra
      nmap
      nodejs
      opencode
      package-version-server
      plantuml
      postgresql_17
      pv
      ripgrep
      ruff
      python3
      basedpyright
      slackdump
      shellcheck
      ssm-session-manager-plugin
      terraform
      tree
      typescript
      watch
      wget
      xz
      yq
      cargo
      clippy
      rustc
    ];

    home.file.".ssh/config".text = ''
      Include ~/.orbstack/ssh/config

      Host *
        ForwardAgent yes
        AddKeysToAgent yes
        IdentityFile ~/.ssh/id_ed25519
    '';

    home.sessionPath =
      (lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
      ])
      ++ [
        "node_modules/.bin"
        "~/.local/npm-packages/bin"
        "~/.local/bin"
        "~/bin"
        "~/go/bin"
        "~/.cargo/bin"
      ];

    home.sessionVariables = {
      SHELL = "${pkgs.fish}/bin/fish";
    };

    programs.awscli = {
      enable = true;
      package = pkgs.awscli.overrideAttrs (_: {
        doCheck = false;
      });
    };

    programs.dircolors.enable = true;
    programs.fish = {
      enable = true;
      plugins = [
        {
          name = "tide";
          src = pkgs.fishPlugins.tide.src;
        }
      ];
      shellAliases = {};
      shellInit = ''
        set -g fish_greeting ""
      '';
    };
    programs.fzf.enable = true;
    programs.gh.enable = true;
    programs.go.enable = true;
    programs.granted = {
      enable = true;
      enableFishIntegration = true;
    };
    programs.jq.enable = true;
    programs.k9s.enable = true;
    programs.mise = {
      enable = false;
      enableFishIntegration = true;
    };
    programs.nix-index.enable = true;
    programs.poetry.enable = true;
    programs.uv.enable = true;
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = ["--cmd cd"];
    };

    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Sean Treadway";
          email = "srt@veo.co";
        };

        ui.merge-editor = "vimdiff";

        fix.tools = {
          ruffcheck = {
            command = [
              "ruff"
              "check"
              "--fix"
              "--stdin-filename=$path"
              "-"
            ];
            patterns = ["glob:'**/*.py'"];
          };

          ruffformat = {
            command = [
              "ruff"
              "format"
              "--stdin-filename=$path"
              "-"
            ];
            patterns = ["glob:'**/*.py'"];
          };

          nixfmt = {
            command = [
              "nixfmt"
              "--verify"
              "--filename=$path"
            ];
            patterns = ["glob:'**/*.nix'"];
          };
        };

        aliases.tug = [
          "bookmark"
          "move"
          "--from"
          "heads(::@- & bookmarks())"
          "--to"
          "@-"
        ];
      };
    };

    programs.git = {
      enable = false;
      settings = {
        user.name = "Sean Treadway";
        user.email = "srt@veo.co";
        aliases.co = "checkout";
      };
    };
  };
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  options.services.sshIdleShutdown = {
    enable = mkEnableOption "SSH idle shutdown service";

    idleMinutes = mkOption {
      type = types.int;
      default = 120;
      description = "Number of minutes to wait before shutting down when no SSH connections are active";
    };
  };

  config = mkMerge [
    (mkIf sshIdleShutdownCfg.enable {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isLinux;
          message = "ssh-idle-shutdown service requires a Linux system with systemd (NixOS)";
        }
      ];

      systemd.services.ssh-idle-shutdown = {
        description = "SSH Idle Shutdown Service";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${sshIdleShutdownScript}";
          User = "root";
        };
      };

      systemd.timers.ssh-idle-shutdown = {
        description = "SSH Idle Shutdown Timer";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "minutely";
          Persistent = true;
        };
      };
    })

    {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
        cudaSupport = true;
        rocmSupport = false;
      };

      nix = {
        package = pkgs.lixPackageSets.stable.lix;
        settings = {
          experimental-features = "nix-command flakes";
          trusted-users = [
            "@wheel"
          ];
          extra-substituters = [
            "https://nix-community.cachix.org"
            "https://nixos-raspberrypi.cachix.org"
          ];
          extra-trusted-substituters = [
            "https://nix-community.cachix.org"
            "https://nixos-raspberrypi.cachix.org"
          ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
          ];
        };
        gc.automatic = true;
      };

      virtualisation.docker = {
        enable = true;
        daemon.settings = {
          experimental = true;
        };
      };

      users.groups.docker = {};

      hardware.graphics.enable = true;
      services.xserver.videoDrivers = ["nvidia"];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = true;
        nvidiaSettings = true;
      };

      hardware.nvidia-container-toolkit.enable = true;

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
      programs.nix-ld.enable = true;

      home-manager = {
        extraSpecialArgs = {inherit inputs;};
        useGlobalPkgs = true;
        useUserPackages = true;
        users.sean = seanHome;
      };

      environment.systemPackages = with pkgs; [
        vim
      ];

      security.sudo.wheelNeedsPassword = false;

      system.stateVersion = "24.05";
    }
  ];
}
