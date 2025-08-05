{ config, pkgs, username ? "sean", homeDirectory ? "/Users/sean", unstablePkgs ? pkgs, ... }:
let
  # Use unstablePkgs for packages from nixpkgs-unstable
  unstable = unstablePkgs;
  
  gcloud-sdk = unstable.google-cloud-sdk.withExtraComponents (with unstable.google-cloud-sdk.components; [
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

  # Use unstable packages for most packages
  home.packages = with unstable; [
    #gst_all_1.gst-plugins-bad
    #gst_all_1.gst-plugins-ugly
    _1password-cli 
    act
    awscli
    aws-sam-cli
    ssm-session-manager-plugin
    basedpyright
    bat
    cacert
    cargo
    claude-code
    clippy
    cloc
    cue
    duckdb
    difftastic
    ffmpeg-full
    fio
    gcloud-sdk
    gg-jj # jj ui
    gh
    git
    git-repo
    graphviz
    grafana-loki
    #granted
    #gst_all_1.gst-plugins-base
    #gst_all_1.gst-plugins-good
    #gst_all_1.gstreamer
    heroku
    htop
    jujutsu
    jq
    k9s
    kubectl
    kustomize
    nixpkgs-fmt
    nixfmt-classic
    nmap
    nodejs_20
    gnumake
    mise
    openapi-generator-cli
    plantuml
    postgresql_17
    pre-commit
    pv
    pyenv
    python312
    ripgrep
    rustc
    shellcheck
    sqlfluff
    terraform
    tree
    uv
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

  home.sessionPath = [
    "node_modules/.bin"
    "${homeDirectory}/bin"
    "${homeDirectory}/go/bin"
    "${homeDirectory}/.cargo/bin"
  ];

  #programs.home-manager.enable = true;

  # Fish shell configuration
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "tide";
        src = unstable.fishPlugins.tide.src;
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

#  programs.granted = {
#    enable = true;
#    enableFishIntegration = true;
#  };

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
    package = unstable.jdk23;
  };

  programs.go = {
    enable = true;
  };
}
