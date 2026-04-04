{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./wireguard.nix
    # ./via.nix
    ../../../modules/nixos/nix.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nx";
  networking.networkmanager.enable = true;

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

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    displayManager.gdm.enable = true;
    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "sean";
    desktopManager.gnome.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ libcap ];
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
          delay = "225";
          repeat-interval = "30";
          repeat = true;
        };
        "org/gnome/desktop/peripherals/mouse" = {
          natural-scroll = true;
        };
        "org/gnome/desktop/screensaver" = {
          lock-enabled = true;
        };
        "org/gnome/desktop/session" = {
          idle-delay = "1800";
        };
      };
    }
  ];

  hardware.openrazer = {
    enable = true;
    users = [ "sean" ];
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

  services.samba.winbindd.enable = false;
  services.samba.nmbd.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.sean = {
    isNormalUser = true;
    description = "Sean Treadway";
    extraGroups = [
      "networkmanager"
      "wheel"
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

  programs = {
    firefox.enable = true;
    steam.enable = true;
    fish.enable = true;
    direnv.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  environment.systemPackages = with pkgs; [
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
    nil
    nixd
    libguestfs
    qemu-utils
    amdgpu_top
    (ffmpeg-full.override { withUnfree = true; })
    vlc
  ];

  security.polkit.enable = true;
  services.accounts-daemon.enable = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=240
    Defaults !tty_tickets
    Defaults timestamp_type=global
  '';

  services.fprintd.enable = true;
  security.pam.services.gdm-fingerprint.fprintAuth = true;
  security.pam.services.gdm.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;

  services.jellyfin.enable = true;

  system.stateVersion = "25.11";
}
