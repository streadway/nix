{
  config,
  lib,
  system,
  pkgs,
  ...
}:

{
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
