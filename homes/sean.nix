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

  home.packages =
    with pkgs;
    [
      _1password-cli
      act
      ssm-session-manager-plugin
      bat
      cacert
      claude-code
      difftastic
      ffmpeg
      gg-jj # jj ui
      grafana-loki
      htop
      nmap
      package-version-server # for Zed
      plantuml
      postgresql_17
      terraform
      wget
    ]
    ++ lib.optional pkgs.stdenv.isDarwin [
      darwin.PowerManagement # caffeniate
    ];

  home.file.".ssh/config" = {
    text = ''
      Host *
        ForwardAgent yes
        AddKeysToAgent yes
        IdentityFile ~/.ssh/id_ed25519
    '';
  };

  home.sessionPath = [
    "node_modules/.bin"
    "~/.local/npm-packages/bin"
    "~/.local/bin"
    "~/bin"
    "~/go/bin"
    "~/.cargo/bin"
  ];

  # Fish shell configuration
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
      # Custom fish shell initialization
      set -g fish_greeting ""  # Disable greeting
    '';
  };

  programs.mise = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.dircolors.enable = true;
  programs.fzf.enable = true;
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.gh.enable = true;

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Sean Treadway";
        email = "srt@veo.co";
      };

      ui = {
        merge-editor = "vimdiff";
      };

      fix.tools.ruffcheck = {
        command = [
          "ruff"
          "check"
          "--fix"
          "--stdin-filename=$path"
          "-"
        ];
        patterns = [ "glob:'**/*.py'" ];
      };

      fix.tools.ruffformat = {
        command = [
          "ruff"
          "format"
          "--stdin-filename=$path"
          "-"
        ];
        patterns = [ "glob:'**/*.py'" ];
      };

      fix.tools.nixfmt = {
        command = [
          "nixfmt"
          "--verify"
          "--filename=$path"
        ];
        patterns = [ "glob:'**/*.nix'" ];
      };

      aliases = {
        tug = [
          "bookmark"
          "move"
          "--from"
          "heads(::@- & bookmarks())"
          "--to"
          "@-"
        ];
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Sean Treadway";
    userEmail = "srt@veo.co";
    aliases = {
      co = "checkout";
    };
    extraConfig = {
      credential."https://github.com".useHttpPath = true;
    };
  };

  programs.nix-index.enable = true;
}
