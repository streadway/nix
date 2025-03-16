{ pkgs, config, vars, inputs, system, stable, ... }:

{
  nix = {
    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";
    };
    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  users.users.${vars.user} = {
    home = "/Users/${vars.user}";
    shell = pkgs.fish;
  };

  home-manager.users.${vars.user} = { ... }: {
    imports = [ ./home.nix ];
    
    # Pass variables to home.nix through home-manager options
    _module.args.username = vars.user;
    _module.args.homeDirectory = "/Users/${vars.user}";
    
    # Explicitly set pkgs to use nixpkgs-unstable
    _module.args.unstablePkgs = pkgs;
  };

  environment = {
    systemPackages = [
      pkgs.mkalias

      pkgs.darwin.apple_sdk.frameworks.CoreFoundation
      pkgs.darwin.apple_sdk.frameworks.CoreServices
      pkgs.darwin.apple_sdk.frameworks.Security
    ];

    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # Enable fish at the system level, but configuration is in home-manager
  programs.fish.enable = true;

  programs.direnv = {
    enable = true;
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    brews = [
    ];

    casks = [
      "firefox"
      "brave-browser"
      "google-chrome"
      "rectangle"
      "orbstack"
      "eul"
      "ghostty"
    ];
  };

  services.redis = {
    enable = true;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database DBuser host      auth-method
      local all     all              trust
      host  all     all   127.0.0.1/32 trust
      host  all     all   192.168.0.0/16 trust
      host  all     all   ::1/128       trust
      host  all     all   all       scram-sha-256

    '';
    dataDir = "/Users/${vars.user}/.local/postgres/17";
    initdbArgs = [ "--locale=en_US.UTF-8" "--encoding=UTF-8" ];
    enableTCPIP = true;
    ensureDatabases = [
      "zola"
    ];
    ensureUsers = [
      {
        name = "zola";
        ensurePermissions = {
          "DATABASE zola" = "ALL PRIVILEGES";
        };
      }
    ];
    extraPlugins = [ ];
    settings = {
      # Disable durability for faster performance
      fsync = false;                     # Don't force syncs to disk
      synchronous_commit = "off";        # Don't wait for WAL writes
      full_page_writes = false;          # Disable full page writes
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system = {
    defaults = {
      NSGlobalDomain = {
        AppleShowAllFiles = true;
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        NSAutomaticPeriodSubstitutionEnabled = false;
        KeyRepeat = 2;
        "com.apple.keyboard.fnState" = true;
      };
      dock = {
        autohide = true;
        autohide-delay = 0.2;
        autohide-time-modifier = 0.1;
        magnification = true;
        mineffect = "scale";
        # minimize-to-application = true;
        orientation = "bottom";
        showhidden = false;
        show-recents = false;
        tilesize = 40;
      };

      CustomUserPreferences = {
        # Settings of plist in ~/Library/Preferences/
        "com.apple.finder" = {
          # Set home directory as startup window
          NewWindowTargetPath = "file:///Users/${vars.user}/";
          NewWindowTarget = "PfHm";
          # Set search scope to directory
          FXDefaultSearchScope = "SCcf";
          # Multi-file tab view
          FinderSpawnTab = true;
        };
        "com.apple.desktopservices" = {
          # Disable creating .DS_Store files in network an USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        # Show battery percentage
        "~/Library/Preferences/ByHost/com.apple.controlcenter".BatteryShowPercentage = true;
        # Privacy
        "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      };
    };
  };

  system.stateVersion = 5;

  security.pam.services.sudo_local.touchIdAuth = true;
} 
