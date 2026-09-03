{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
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
      google-cloud-sdk
      grafana-loki
      graphviz
      heroku
      htop
      hyperfine
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.antigravity-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-no-fhs
      inputs.antigravity-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
      inputs.antigravity-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide-no-fhs
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
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../_modules/wayland-push-to-talk-fix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
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

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5;
    efi.canTouchEfiVariables = true;
  };

  boot.binfmt = {
    emulatedSystems = ["aarch64-linux"];
    preferStaticEmulators = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/68888b99-eb9a-46be-98e4-76cb5fc2c72e";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/EA25-326B";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  hardware.openrazer = {
    enable = true;
    users = ["sean"];
  };

  networking = {
    hostName = "nx";
    networkmanager.enable = true;
    nftables.enable = true;
    useNetworkd = true;
    firewall = {
      allowedUDPPorts = [51820];
      allowedTCPPorts = [31369];
      checkReversePath = "loose";
    };
  };

  services.mullvad-vpn = {
    enable = true;
    gui.enable = true;
  };

  systemd.network = {
    enable = true;
    networks."50-wg0" = {
      matchConfig.Name = "wg0";
      address = [
        "fc00:bbbb:bbbb:bb01::4:d65d/128"
        "10.67.214.94/32"
      ];
      domains = ["~."];
      dns = ["10.64.0.1"];
      networkConfig = {
        DNSDefaultRoute = true;
      };
      routingPolicyRules = [
        {
          Priority = 8;
          To = "193.138.7.157/32";
        }
        {
          Priority = 9;
          User = "tm";
          Family = "both";
          SuppressPrefixLength = 0;
          Table = "main";
        }
        {
          Priority = 10;
          User = "tm";
          Family = "both";
          Table = 1000;
        }
      ];
    };

    netdevs."50-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };

      wireguardConfig = {
        ListenPort = 51820;
        PrivateKeyFile = "/etc/wireguard/great_salmon.key";
        FirewallMark = 42;
      };

      wireguardPeers = [
        {
          PublicKey = "xeHVhXxyyFqUEE+nsu5Tzd/t9en+++4fVFcSFngpcAU=";
          AllowedIPs = [
            "::0/0"
            "0.0.0.0/0"
          ];
          Endpoint = "193.138.7.157:51820";
          RouteTable = 1000;
        }
      ];
    };
  };

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=240
    Defaults !tty_tickets
    Defaults timestamp_type=global
  '';
  security.polkit.enable = true;
  security.rtkit.enable = true;

  users.users.sean = {
    isNormalUser = true;
    description = "Sean";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "uinput"
    ];
    shell = pkgs.fish;
  };

  users.users.tm = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  environment = {
    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };

    systemPackages = with pkgs; [
      zed-editor
      git
      jj
      vim
      unzip
      dig
      _1password-gui
      _1password-cli
      qbittorrent

      lutris
      wineWow64Packages.staging
      winetricks
      discord
      vesktop
      nil
      nixd
      libguestfs
      qemu-utils
      amdgpu_top
      (ffmpeg-full.override {withUnfree = true;})
      vlc
      wireguard-tools
      iproute2
      nftables
    ];
  };

  programs.dconf.enable = true;
  programs.dconf.profiles.tm.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = "Nordic";
          color-scheme = "prefer-dark";
        };
      };
    }
  ];

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = "Adwaita";
          color-scheme = "prefer-dark";
        };
        "org/gnome/desktop/peripherals/keyboard" = {
          delay = lib.gvariant.mkUint32 225;
          repeat-interval = lib.gvariant.mkUint32 30;
          repeat = true;
        };
        "org/gnome/desktop/peripherals/mouse" = {
          natural-scroll = true;
        };
        "org/gnome/desktop/screensaver" = {
          lock-enabled = true;
        };
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 1800;
        };
      };
    }
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libcap
    ];
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.firefox.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  programs.fish.enable = true;
  programs.direnv.enable = true;

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    useGlobalPkgs = true;
    useUserPackages = true;
    users.sean = seanHome;
  };

  services.udev.extraHwdb = ''
    # Razer Naga Epic Chroma side keypad (currently /dev/input/event6 on nx)
    # Remap the 12-button thumb grid from 1..= to F1..F12, except 4 -> KP_EQUAL.
    evdev:input:b0003v1532p003Ee0111*
      KEYBOARD_KEY_7001e=f1
      KEYBOARD_KEY_7001f=f2
      KEYBOARD_KEY_70020=f3
      KEYBOARD_KEY_70021=kpequal
      KEYBOARD_KEY_70022=f5
      KEYBOARD_KEY_70023=f6
      KEYBOARD_KEY_70024=f7
      KEYBOARD_KEY_70025=f8
      KEYBOARD_KEY_70026=f9
      KEYBOARD_KEY_70027=f10
      KEYBOARD_KEY_7002d=f11
      KEYBOARD_KEY_7002e=f12
  '';

  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.input-remapper.enable = true;

  services.wayland-push-to-talk-fix = {
    enable = false;
    device = "/dev/input/by-id/usb-Razer_Razer_Naga_Epic_Chroma-event-mouse";
    keyCode = "BTN_SIDE";
    keyName = "MOUSE8";
  };

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  services.printing = {
    enable = true;
    openFirewall = true;
    drivers = [
      pkgs.cups-brother-hl1210w
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    winbindd.enable = false;
    nmbd.enable = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixOS Samba Server";
        "netbios name" = "nx";
        "security" = "user";
        "hosts allow" = "192.168. 127. localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
      };
      homes = {
        "comment" = "Home Directories";
        "browseable" = "no";
        "read only" = "no";
        "create mask" = "0700";
        "directory mask" = "0700";
        "valid users" = "%S";
        "invalid users" = "root";
      };
    };
  };

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.accounts-daemon.enable = true;

  system.stateVersion = "25.11";
}
