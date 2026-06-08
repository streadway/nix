{
  inputs,
  pkgs,
  ...
}:
let
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
        difftastic
        ffmpeg
        gemini-cli
        google-cloud-sdk
        grafana-loki
        htop
        inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
        jjui
        nmap
        opencode
        package-version-server
        plantuml
        postgresql_17
        ripgrep
        ssm-session-manager-plugin
        terraform
        wget
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
      programs.mise = {
        enable = false;
        enableFishIntegration = true;
      };
      programs.nix-index.enable = true;
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
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-wsl.nixosModules.default
    inputs.nixvim.nixosModules.nixvim
    nixvimConfig
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = "nix-command flakes";
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
      options = "--delete-older-than 7d";
    };
  };

  environment = {
    systemPackages = [
      pkgs.tzdata
      pkgs.vim
      pkgs.git
      pkgs.fishPlugins.tide
    ];

    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };
  };

  users.users.sean = {
    isNormalUser = true;
    home = "/home/sean";
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  programs.direnv.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.sean = seanHome;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };

  wsl = {
    enable = true;
    defaultUser = "sean";
  };

  system.stateVersion = "24.05";
}
