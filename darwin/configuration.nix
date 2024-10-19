# vim: ts=2 sw=2 et

{ pkgs, config, vars, ... }:

let
in
{
  imports = [
    ../modules/nvim.nix
    ./pr-122-fix-fish.nix
  ];

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

  home-manager.users.${vars.user} = import ../home.nix;

  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = [
      pkgs.mkalias
      pkgs.fishPlugins.tide
    ];

    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  fonts.packages = [
    (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;

  programs.direnv = {
    enable = true;
    #loadInNixShell = true;
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    casks = [
      "firefox"
      "brave-browser"
      "google-chrome"
      "rectangle"
      "orbstack"
      "eul"
    ];
  };

  services.nix-daemon.enable = true;

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
}
