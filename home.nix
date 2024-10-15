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
    ".ssh/config".text = ''
      Host github.com
        AddKeysToAgent yes
        UseKeychain yes
        IdentityFile ~/.ssh/id_ed25519
    '';
  };

  home.sessionVariables = {
    EDITOR="nvim";
  };

  home.sessionPath = [
    "node_modules/.bin"
    "/Users/sean/bin"
    "/Users/sean/go/bin"
    "/Users/sean/.cargo/bin"
  ];

  programs.home-manager.enable = true;

  programs.direnv.enable = true;

  programs.nixvim = {
    enable = true;
    enableMan = false;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    globals = {
      mapleader = ",";
      maplocalleader = ",";
    };

    opts = {
      number = true;

      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;

      autoindent = true;
      smartindent = true;
      smarttab = true;

      cursorline = true;
    };

  };

  programs.fish = {
    enable = true;

    plugins = with pkgs.fishPlugins; [
      { name = "tide"; src = tide.src; }
    ];

    shellAliases = {
      assume="source ${granted}/share/assume.fish";
    };

    functions = {
      config = {
        body = "git --git-dir=$HOME/.config.git/ --work-tree=$HOME $argv";
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

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  #programs.vim = {
  #  enable = true;

  #  plugins = with pkgs.vimPlugins; [
  #    gruvbox-community
  #    typescript-vim
  #    vim-airline
  #    vim-nix
  #  ];

  #  settings = {
  #    tabstop = 2;
  #    shiftwidth = 2;
  #    expandtab = true;
  #  };

  #  extraConfig = ''
  #    let mapleader = ","
  #    let maplocalleader = ","

  #    set list
  #    set smartindent
  #    set smarttab

  #    set background=dark
  #    colorscheme gruvbox
  #    syntax on
  #  '';
  #};

  programs.java = {
    enable = true;
    package = pkgs.openjdk22;
  };

  programs.go = {
    enable = true;
  };
}
