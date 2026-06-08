{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  primaryUser = lib.attrByPath [ "system" "primaryUser" ] null config;

  seanHome =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.username = "sean";
      home.homeDirectory =
        if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";
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
        (lib.optionals pkgs.stdenv.isDarwin [
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
        shellAliases = { };
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
        options = [ "--cmd cd" ];
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
              patterns = [ "glob:'**/*.py'" ];
            };

            ruffformat = {
              command = [
                "ruff"
                "format"
                "--stdin-filename=$path"
                "-"
              ];
              patterns = [ "glob:'**/*.py'" ];
            };

            nixfmt = {
              command = [
                "nixfmt"
                "--verify"
                "--filename=$path"
              ];
              patterns = [ "glob:'**/*.nix'" ];
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

  nixvimConfig =
    { pkgs, ... }:
    {
      programs.nixvim = {
        enable = true;
        enableMan = false;
        viAlias = true;
        vimAlias = true;

        nixpkgs.useGlobalPackages = true;

        keymaps = [ ];

        globals = {
          mapleader = ",";
          maplocalleader = ",";
        };

        extraPlugins = [ pkgs.vimPlugins.gruvbox ];

        dependencies.direnv.enable = false;

        plugins = {
          lightline.enable = true;
          nix.enable = true;
          direnv = {
            enable = true;
            package = pkgs.vimPlugins.direnv-vim;
          };
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
                options.desc = "Telescope Git Files";
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
          cmdheight = 0;
        };
      };
    };
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.nixvim.nixDarwinModules.nixvim
    nixvimConfig
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  system = {
    primaryUser = "sean";
    primaryUserHome = "/Users/sean";
  };

  users.users.sean = {
    home = "/Users/sean";
    shell = pkgs.fish;
  };

  environment = {
    shells = [ pkgs.fish ];
    systemPackages = with pkgs; [
      vim
    ];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  nix = {
    enable = true;
    package = pkgs.nix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = lib.mkForce [
        "https://cache.nixos.org/"
      ];

      trusted-public-keys = lib.mkForce [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      trusted-users = lib.mkForce (
        [
          "root"
        ]
        ++ lib.optionals (primaryUser != null) [
          primaryUser
        ]
      );

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

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    optimise.automatic = true;
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "sean";
    autoMigrate = true;
    taps = {
      "schpet/homebrew-tap" = inputs.schpet-tap;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };

    brews = [
      "schpet/homebrew-tap/linear"
      "mole"
    ];

    casks = [
      "firefox"
      "chromedriver"
      "brave-browser"
      "google-chrome"
      "rectangle"
      "orbstack"
      "eul"
      "ghostty"
    ];
  };

  nixpkgs.overlays = [
    (
      _final: prev:
      let
        direnvNoCheck = prev.direnv.overrideAttrs (_: {
          doCheck = false;
          doInstallCheck = false;
        });
      in
      {
        direnv = direnvNoCheck;
        vimPlugins = prev.vimPlugins // {
          direnv-vim = prev.vimPlugins.direnv-vim.overrideAttrs (_: {
            preFixup = ''
              substituteInPlace $out/autoload/direnv.vim \
                --replace-fail "let s:direnv_cmd = get(g:, 'direnv_cmd', 'direnv')" \
                  "let s:direnv_cmd = get(g:, 'direnv_cmd', '${lib.getBin direnvNoCheck}/bin/direnv')"
            '';
          });
        };
      }
    )
  ];

  programs.fish.enable = true;
  programs.direnv.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.sean = seanHome;
  };

  services.redis.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database DBuser host      auth-method
      local all     all              trust
      host  all     all   127.0.0.1/32 trust
      host  all     all   192.168.0.0/16 trust
      host  all     all   ::1/128       trust
      host  all     all   all       scram-sha-256

    '';
    dataDir = "/Users/sean/.local/postgres/18";
    initdbArgs = [
      "--locale=en_US.UTF-8"
      "--encoding=UTF-8"
    ];
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
      {
        name = "flappy";
        ensurePermissions = {
          "DATABASE flappy" = "ALL PRIVILEGES";
        };
      }
    ];
    extraPlugins = [ ];
    settings = {
      fsync = false;
      synchronous_commit = "off";
      full_page_writes = false;
      shared_preload_libraries = "pg_stat_statements";
      "pg_stat_statements.track" = "all";
      "pg_stat_statements.max" = "100000";
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {
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
      orientation = "bottom";
      showhidden = false;
      show-recents = false;
      tilesize = 40;
    };
    controlcenter = {
      BatteryShowPercentage = true;
      Bluetooth = true;
      Display = true;
      NowPlaying = true;
      Sound = true;
    };

    CustomUserPreferences = {
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
    };
  };

  system.stateVersion = 5;

  security.pam.services.sudo_local.touchIdAuth = true;
}
