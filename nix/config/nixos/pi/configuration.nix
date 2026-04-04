{
  config,
  pkgs,
  lib,
  nixos-raspberrypi,
  ...
}:
{
  # Hardware specific configuration
  imports = with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.page-size-16k
    raspberry-pi-5.display-vc4
  ];

  # Basic system configuration
  networking.hostName = "pi";
  time.timeZone = "Europe/Copenhagen";
  system.stateVersion = "24.05";

  # SSH configuration for remote management
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
    # Use socket activation to keep connections alive through restarts
    startWhenNeeded = true;
  };

  # Prevent SSH from being fully restarted during system switches
  # This keeps existing connections alive
  systemd.services.sshd = {
    stopIfChanged = false;
    reloadIfChanged = true;
  };

  # Enable mDNS for easier access via pi.local
  services.avahi = {
    enable = true;
    # openFirewall = true;
    nssmdns4 = true;
    allowInterfaces = [ "end0" ];
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      workstation = true;
    };
  };

  # SSH keys for root user
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoDCPzWaZ2g6eVgPUfVHWnpz67VO7GsKL9gxFuqLYJL veo"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6519jnei+uHIWFPHyFQYeI7cZhpT2+PBPitCATB5DS nx"
  ];

  # System packages
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

  # Keep the USB media library mounted declaratively so it is restored across
  # rebuilds and reboots without relying on mutable mount commands.
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

  # Enable Docker for BlockyUI
  virtualisation.docker.enable = true;

  # PostgreSQL for Blocky query logging
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "blocky" ];
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

  # Grant Grafana read access to blocky database
  systemd.services.postgresql-grant-grafana = {
    after = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    script = ''
      ${pkgs.postgresql}/bin/psql -d blocky -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana; GRANT USAGE ON SCHEMA public TO grafana;"
    '';
  };

  # Grafana for DNS query visualization
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
    # Jellyfin writes metadata into /mnt/media; use a collaborative umask so
    # new files are 0664 and directories are 0775 for SMB access.
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

  services.samba.nmbd.enable = true;
  services.samba.winbindd.enable = false;

  # Import Blocky dashboard from Grafana.com
  systemd.services.grafana-import-blocky-dashboard = {
    wantedBy = [ "multi-user.target" ];
    after = [ "grafana.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/grafana/dashboards
      ${pkgs.curl}/bin/curl -o /var/lib/grafana/dashboards/blocky-postgres.json \
        https://grafana.com/api/dashboards/17996/revisions/latest/download
      ${pkgs.gnused}/bin/sed -i \
        's/''${DS_BLOCKY-POSTGRESQL}/blocky-postgresql/g' \
        /var/lib/grafana/dashboards/blocky-postgres.json
      ${pkgs.curl}/bin/curl -o /var/lib/grafana/dashboards/blocky-prometheus.json \
        https://grafana.com/api/dashboards/13768/revisions/latest/download
      ${pkgs.gnused}/bin/sed -i \
        -e 's/''${DS_PROMETHEUS}/prometheus/g' \
        -e 's|''${VAR_BLOCKY_URL}|http://192.168.178.2:4000|g' \
        -e 's/pod=~\\"\\$pod\\"/instance=~\\"\\$instance\\"/g' \
        -e 's/label_values(blocky_blocking_enabled,pod)/label_values(blocky_blocking_enabled,instance)/g' \
        -e '0,/\"name\": \"pod\"/s/\"name\": \"pod\"/\"name\": \"instance\"/' \
        /var/lib/grafana/dashboards/blocky-prometheus.json
      ${pkgs.coreutils}/bin/chown -R grafana:grafana /var/lib/grafana/dashboards
    '';
  };

  # Blocky DNS ad-blocker
  services.blocky = {
    enable = true;
    settings = {
      # Listen on standard DNS port (IPv4 and IPv6)
      ports.dns = ":53";
      # HTTP API for management and metrics
      ports.http = ":4000";

      # Upstream DNS servers
      upstreams.groups.default = [
        "https://one.one.one.one/dns-query" # Cloudflare DNS over HTTPS
      ];

      # Bootstrap DNS for initial DoH resolution
      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };

      # Ad blocking configuration
      blocking = {
        denylists = {
          ads = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
        };
        clientGroupsBlock = {
          default = [ "ads" ];
        };
      };

      # DNS caching
      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };

      # Enable Prometheus metrics
      prometheus.enable = true;

      # Query logging to PostgreSQL
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
        job_name = "blocky";
        metrics_path = "/metrics";
        static_configs = [
          {
            targets = [ "localhost:4000" ];
          }
        ];
      }
    ];
  };

  # Networking configuration
  networking = {
    useDHCP = lib.mkDefault true;
    # The Pi serves DNS for the LAN, so it must not consume its own DHCP-advertised
    # resolver address. Fallback to the host's upstream resolver to the router.
    nameservers = [
      "192.168.178.2"
      "192.168.178.1"
    ];
    dhcpcd.extraConfig = ''
      nohook resolv.conf
    '';
  };

  # Open DNS, Blocky API, BlockyUI, and Grafana ports in firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      53
      4000
      3000
      3001
    ];
    allowedUDPPorts = [ 53 ];
  };

  # BlockyUI container
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      blocky-ui = {
        image = "gabrielduartem/blocky-ui:latest";
        ports = [ "3000:3000" ];
        environment = {
          BLOCKY_API_URL = "http://127.0.0.1:4000";
        };
      };
    };
  };

  # System tags for image identification
  system.nixos.tags = [
    "raspberry-pi-5"
    config.boot.kernelPackages.kernel.version
  ];
}
