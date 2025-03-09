{ config, pkgs, username ? "sean", homeDirectory ? "/Users/sean", ... }:
let
  gcloud-sdk = pkgs.google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
    cloud-run-proxy
    cloud-sql-proxy
    log-streaming
    bq
  ]);
in
{
  # Use the passed username and homeDirectory
  home.username = username;
  home.homeDirectory = homeDirectory;

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    #gst_all_1.gst-plugins-bad
    #gst_all_1.gst-plugins-ugly
    _1password-cli
    act
    awscli
    aws-sam-cli
    ssm-session-manager-plugin
    bat
    cacert
    cargo
    clippy
    cloc
    cue
    duckdb
    #ffmpeg-full
    fio
    gcloud-sdk
    gh
    git
    git-repo
    graphviz
    #gst_all_1.gst-plugins-base
    #gst_all_1.gst-plugins-good
    #gst_all_1.gstreamer
    heroku
    htop
    jujutsu
    jq
    kubectl
    kustomize
    nixpkgs-fmt
    nixfmt-classic
    nmap
    nodejs_20
    openapi-generator-cli
    plantuml
    postgresql_15
    pre-commit
    pv
    pyenv
    python312
    uv
    ripgrep
    rustc
    shellcheck
    sqlfluff
    terraform
    tree
    watch
    wget
    xz
    yq

    # python extensions
    #clang
    #openssl
    #zlib
    #libffi
  ];

  home.file.".ssh/config" = {
    text = ''
      Host *
        ForwardAgent yes
        AddKeysToAgent yes
        IdentityFile ~/.ssh/id_ed25519
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Use the passed homeDirectory for paths
  home.sessionPath = [
    "node_modules/.bin"
    "${homeDirectory}/bin"
    "${homeDirectory}/go/bin"
    "${homeDirectory}/.cargo/bin"
  ];

  programs.home-manager.enable = true;

  # Fish shell configuration
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
    ];
    shellAliases = {
      ll = "ls -la";
      g = "git";
    };
    shellInit = ''
      # Custom fish shell initialization
      set -g fish_greeting ""  # Disable greeting
    '';
  };

  programs.granted = {
    enable = true;
  };

  programs.dircolors.enable = true;
  programs.fzf.enable = true;
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
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

  programs.java = {
    enable = true;
    package = pkgs.jdk23;
  };

  programs.go = {
    enable = true;
  };
}
