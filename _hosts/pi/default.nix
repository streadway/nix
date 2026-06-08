{
  config,
  lib,
  nixos-raspberrypi,
  pkgs,
  ...
}: let
  inherit
    (lib)
    escapeShellArgs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;

  hdIdleCfg = config.services.hd-idle;
in {
  imports = with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.page-size-16k
    raspberry-pi-5.display-vc4
  ];

  options.services.hd-idle = {
    enable = mkEnableOption "hd-idle disk spindown service";

    package = mkPackageOption pkgs "hd-idle" {};

    args = mkOption {
      type = types.listOf types.str;
      default = [];
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

  config = mkMerge [
    (mkIf hdIdleCfg.enable {
      systemd.services.hd-idle = {
        description = "hd-idle disk spindown daemon";
        after = ["local-fs.target"];
        wants = ["local-fs.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe hdIdleCfg.package} ${escapeShellArgs hdIdleCfg.args}";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    })

    {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };

      nix = {
        package = lib.mkForce pkgs.nix;
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

      networking.hostName = "pi";
      time.timeZone = "Europe/Copenhagen";
      system.stateVersion = "24.05";

      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "yes";
        };
        startWhenNeeded = true;
      };

      systemd.services.sshd = {
        stopIfChanged = false;
        reloadIfChanged = true;
      };

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        allowInterfaces = ["end0"];
        publish = {
          enable = true;
          addresses = true;
          domain = true;
          workstation = true;
        };
      };

      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoDCPzWaZ2g6eVgPUfVHWnpz67VO7GsKL9gxFuqLYJL veo"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6519jnei+uHIWFPHyFQYeI7cZhpT2+PBPitCATB5DS nx"
      ];

      environment.systemPackages = with pkgs; [
        vim
        git
        htop
        tmux
      ];

      users.groups.media.gid = 2000;
      users.users.media-share = {
        isSystemUser = true;
        description = "Anonymous SMB writer for /mnt/media";
        group = "media";
      };

      fileSystems."/mnt/media" = {
        device = "/dev/disk/by-uuid/f4743e05-2236-47c0-bbbc-3aefb16ee327";
        fsType = "ext4";
        options = [
          "nofail"
          "noatime"
          "x-systemd.automount"
          "x-systemd.device-timeout=10s"
          "x-systemd.idle-timeout=15min"
        ];
      };

      services.hd-idle = {
        enable = true;
        args = [
          "-i"
          "0"
          "-c"
          "scsi"
          "-s"
          "1"
          "-a"
          "/dev/disk/by-uuid/f4743e05-2236-47c0-bbbc-3aefb16ee327"
          "-i"
          "1800"
        ];
      };

      virtualisation.docker.enable = true;

      services.postgresql = {
        enable = true;
        ensureDatabases = ["blocky"];
        ensureUsers = [
          {
            name = "blocky";
            ensureDBOwnership = true;
          }
          {
            name = "grafana";
          }
        ];
        authentication = ''
          local all all trust
          host all all 127.0.0.1/32 trust
          host all all ::1/128 trust
        '';
      };

      systemd.services.postgresql-grant-grafana = {
        after = ["postgresql.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "postgres";
        };
        script = ''
          ${pkgs.postgresql}/bin/psql -d blocky -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana; GRANT USAGE ON SCHEMA public TO grafana;"
        '';
      };

      services.grafana = {
        enable = true;
        settings = {
          panels.disable_sanitize_html = true;
          server = {
            http_addr = "0.0.0.0";
            http_port = 3001;
          };
        };
        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Blocky PostgreSQL";
              type = "postgres";
              uid = "blocky-postgresql";
              url = "localhost:5432";
              user = "grafana";
              jsonData = {
                database = "blocky";
                sslmode = "disable";
                postgresVersion = 1500;
              };
              isDefault = true;
            }
            {
              name = "Prometheus";
              type = "prometheus";
              uid = "prometheus";
              url = "http://localhost:9090";
              isDefault = false;
            }
          ];
          dashboards.settings.providers = [
            {
              name = "Blocky";
              options.path = "/var/lib/grafana/dashboards";
            }
          ];
        };
      };

      services.jellyfin = {
        enable = true;
        openFirewall = true;
        user = "media-share";
        group = "media";
      };

      systemd.services.jellyfin.serviceConfig = {
        UMask = lib.mkForce "0002";
      };

      services.minidlna = {
        enable = true;
        openFirewall = true;
        settings = {
          inotify = "yes";
          media_dir = [
            "VP,/mnt/media/Movies"
            "VP,/mnt/media/Series"
          ];
        };
      };

      services.samba = {
        enable = true;
        openFirewall = true;
        nmbd.enable = true;
        winbindd.enable = false;
        settings = {
          global = {
            "workgroup" = "WORKGROUP";
            "server string" = "Pi Media Share";
            "netbios name" = "pi";
            "security" = "user";
            "hosts allow" = "192.168.178. 127.0.0.1 localhost";
            "hosts deny" = "0.0.0.0/0";
            "guest account" = "media-share";
            "map to guest" = "bad user";
            "load printers" = "no";
            "printing" = "bsd";
            "printcap name" = "/dev/null";
            "disable spoolss" = "yes";
          };
          media = {
            "comment" = "Pi media library";
            "path" = "/mnt/media";
            "browseable" = "yes";
            "read only" = "no";
            "writable" = "yes";
            "guest ok" = "yes";
            "guest only" = "yes";
            "force user" = "media-share";
            "force group" = "media";
            "create mask" = "0664";
            "directory mask" = "2775";
          };
        };
      };

      services.blocky = {
        enable = true;
        settings = {
          ports.dns = ":53";
          ports.http = ":4000";

          upstreams.groups.default = [
            "https://one.one.one.one/dns-query"
          ];

          bootstrapDns = {
            upstream = "https://one.one.one.one/dns-query";
            ips = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };

          blocking = {
            denylists = {
              ads = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"];
            };
            clientGroupsBlock = {
              default = ["ads"];
            };
          };

          caching = {
            minTime = "5m";
            maxTime = "30m";
            prefetching = true;
          };

          prometheus.enable = true;

          queryLog = {
            type = "postgresql";
            target = "postgres://blocky@localhost:5432/blocky?sslmode=disable";
            logRetentionDays = 30;
            flushInterval = "30s";
            fields = [
              "clientIP"
              "clientName"
              "responseReason"
              "responseAnswer"
              "question"
              "duration"
            ];
          };
        };
      };

      services.prometheus = {
        enable = true;
        port = 9090;
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = ["127.0.0.1:9100"];
              }
            ];
          }
          {
            job_name = "blocky";
            metrics_path = "/metrics";
            static_configs = [
              {
                targets = ["localhost:4000"];
              }
            ];
          }
        ];
      };

      services.prometheus.exporters.node = {
        enable = true;
        listenAddress = "127.0.0.1";
        enabledCollectors = [
          "processes"
          "systemd"
          "thermal_zone"
        ];
      };

      networking = {
        useDHCP = lib.mkDefault true;
        nameservers = [
          "192.168.178.2"
          "192.168.178.1"
        ];
        dhcpcd.extraConfig = ''
          nohook resolv.conf
        '';
        firewall = {
          enable = true;
          allowedTCPPorts = [
            53
            4000
            3000
            3001
          ];
          allowedUDPPorts = [53];
        };
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          blocky-ui = {
            image = "gabrielduartem/blocky-ui:latest";
            ports = ["3000:3000"];
            environment = {
              BLOCKY_API_URL = "http://127.0.0.1:4000";
            };
          };
        };
      };

      system.nixos.tags = [
        "raspberry-pi-5"
        config.boot.kernelPackages.kernel.version
      ];
    }
  ];
}
