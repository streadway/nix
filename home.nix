{ config, pkgs, ... }:
let
  granted = pkgs.granted.override { withFish = true; };
  gcloud-sdk = pkgs.google-cloud-sdk.withExtraComponents( with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
    bq
  ]);
in {
  home.username = "sean";
  home.homeDirectory = "/Users/sean";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    #gst_all_1.gst-plugins-bad
    #gst_all_1.gst-plugins-ugly
    _1password
    alacritty
    awscli2
    cacert
    cargo
    clippy
    cloc
    ffmpeg-full
    fio
    gcloud-sdk
    gh
    git
    granted
    graphviz
    #gst_all_1.gst-plugins-base
    #gst_all_1.gst-plugins-good
    #gst_all_1.gstreamer
    heroku
    htop
    jq
    kubectl
    lzma
    nixpkgs-fmt
    nmap
    nodejs_20
    openapi-generator-cli
    plantuml
    postgresql_15
    pre-commit
    pv
    pyenv
    python312
    ripgrep
    rustc
    shellcheck
    tree
    watch
    wget
    yq

    # python extensions
    #clang
    #openssl
    #zlib
    #libffi
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".ssh/config".text = ''
      Host github.com
        AddKeysToAgent yes
        UseKeychain yes
        IdentityFile ~/.ssh/id_ed25519
    '';
  };

  home.sessionVariables = {
    EDITOR="vim";
  };

  home.sessionPath = [
    "node_modules/.bin"
    "/Users/sean/bin"
    "/Users/sean/go/bin"
    "/Users/sean/.cargo/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/Users/sean/.modular/pkg/packages.modular.com_mojo/bin"
  ];

  programs.home-manager.enable = true;

  programs.direnv.enable = true;

  programs.fish = {
    enable = true;

    plugins = with pkgs.fishPlugins; [
      { name = "tide"; src = tide.src; }
    ];

    shellAliases = {
      # aws="op plugin run -- aws";
      assume="source ${granted}/share/assume.fish";
    };

    shellInit = 
    ''
    if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    end

    set -gx HOMEBREW_PREFIX "/opt/homebrew";
    set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
    set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
    fish_add_path -gP "/opt/homebrew/bin" "/opt/homebrew/sbin";
    ! set -q MANPATH; and set MANPATH ""; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
    ! set -q INFOPATH; and set INFOPATH ""; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;
    '';

    functions = {
      config = {
        body = "git --git-dir=$HOME/.config.git/ --work-tree=$HOME $argv";
      };
      "source.env" = ''
        set -f envfile "$argv"
        if not test -f "$envfile"
          echo "Unable to load $envfile"
          return 1
        end
        while read line
          if not string match -qr '^#|^$' "$line"
            set item (string split -m 1 '=' $line)
            set -gx $item[1] $item[2]
            echo "Exported key $item[1]"
          end
        end < "$envfile"
      '';
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

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  programs.vim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      gruvbox-community
      typescript-vim
      vim-airline
      vim-nix
    ];

    settings = {
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
    };

    extraConfig = ''
      let mapleader = ","
      let maplocalleader = ","

      set list
      set smartindent
      set smarttab

      set background=dark
      colorscheme gruvbox
      syntax on
    '';
  };

  programs.java = {
    enable = true;
    package = pkgs.openjdk22;
  };

  programs.go = {
    enable = true;
  };
}
