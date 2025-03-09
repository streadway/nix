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

  home-manager.users.${vars.user} = import ./home.nix;

  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = [
      pkgs.mkalias
      # Fish plugins are now managed by home-manager

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
  programs.zsh.enable = true;

  programs.direnv = {
    enable = true;
    #loadInNixShell = true;
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

  services.nix-daemon.enable = true;

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

  security.pam.enableSudoTouchIdAuth = true;
  
  # Import the nvim module at the user level instead of system level
  programs.nixvim = {
    enable = true;
    enableMan = false;
    viAlias = true;
    vimAlias = true;

    keymaps = [
    ];

    globals = {
      mapleader = ",";
      maplocalleader = ",";
    };

    extraPlugins = [ pkgs.vimPlugins.gruvbox ];

    plugins = {
      lightline.enable = true;
      nix.enable = true;
      direnv.enable = true;
      auto-save.enable = true;
      orgmode.enable = true;
      web-devicons.enable = true;
      treesitter.enable = true;
      noice.enable = true;
      which-key.enable = true;
      gitsigns = {
        enable = true;
        settings.current_line_blame = true;
      };

      telescope = {
        enable = true;
        keymaps = {
          "<C-p>" = {
            action = "git_files";
            options = {
              desc = "Telescope Git Files";
            };
          };
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "find_buffers";
          "<leader>fd" = "file_browser";
        };
        extensions.file-browser.enable = true;
      };

      cmp = {
        enable = true;
        autoEnableSources = true;
      };
      cmp-nvim-lsp.enable = true;
      cmp-treesitter.enable = true;

      lsp = {
        enable = true;
        servers = {
          pyright.enable = true;
          nixd.enable = true;
        };
      };
    };

    colorschemes.gruvbox.enable = true;

    opts = {
      number = true;

      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;

      autoindent = true;
      smartindent = true;
      smarttab = true;

      #cursorline = true;
      cmdheight = 0;
    };
  };
} 
