{
  config,
  pkgs,
  lib,
  nixos-raspberrypi,
  ...
}: {
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
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
    };
  };

  # SSH keys for root user
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoDCPzWaZ2g6eVgPUfVHWnpz67VO7GsKL9gxFuqLYJL srt@veo.co"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
  ];

  # Enable Docker for BlockyUI
  virtualisation.docker.enable = true;

  # PostgreSQL for Blocky query logging
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

  # Grant Grafana read access to blocky database
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

  # Grafana for DNS query visualization
  services.grafana = {
    enable = true;
    settings = {
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
          database = "blocky";
          user = "grafana";
          jsonData = {
            sslmode = "disable";
            postgresVersion = 1500;
          };
          isDefault = true;
        }
        {
          name = "Prometheus";
          type = "prometheus";
          uid = "prometheus";
          url = "http://localhost:4000";
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

  # Import Blocky dashboard from Grafana.com
  systemd.services.grafana-import-blocky-dashboard = {
    wantedBy = ["multi-user.target"];
    after = ["grafana.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/grafana/dashboards
      ${pkgs.curl}/bin/curl -o /var/lib/grafana/dashboards/blocky-postgres.json \
        https://grafana.com/api/dashboards/17996/revisions/latest/download
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
        ips = ["1.1.1.1" "1.0.0.1"];
      };

      # Ad blocking configuration
      blocking = {
        denylists = {
          ads = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"];
        };
        clientGroupsBlock = {
          default = ["ads"];
        };
      };

      # DNS caching
      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };

      # Enable Prometheus metrics
      prometheus = {
        enable = true;
      };

      # Query logging to PostgreSQL
      queryLog = {
        type = "postgresql";
        target = "postgres://blocky@localhost:5432/blocky?sslmode=disable";
        logRetentionDays = 30;
        flushInterval = "30s";
        fields = ["clientIP" "clientName" "responseReason" "responseAnswer" "question" "duration"];
      };
    };
  };

  # Networking configuration
  networking.useDHCP = lib.mkDefault true;

  # Open DNS, Blocky API, BlockyUI, and Grafana ports in firewall
  networking.firewall = {
    allowedTCPPorts = [53 4000 3000 3001];
    allowedUDPPorts = [53];
  };

  # BlockyUI container
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

  # System tags for boot loader
  system.nixos.tags = let
    cfg = config.boot.loader.raspberryPi;
  in [
    "raspberry-pi-${cfg.variant}"
    cfg.bootloader
    config.boot.kernelPackages.kernel.version
  ];
}
