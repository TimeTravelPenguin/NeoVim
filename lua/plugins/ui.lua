return {
  {
    "alexghergh/nvim-tmux-navigation",
    config = function()
      require "configs.tmux-navigation"
    end,
  },

  {
    "nvim-tree/nvim-web-devicons",
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        integrations = {
          bufferline = false,
          gitsigns = true,
          mason = true,
          neogit = true,
          cmp = true,
          dap = true,
          dap_ui = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
            inlay_hints = {
              background = true,
            },
          },
          treesitter = true,
          telescope = {
            enabled = true,
            style = "nvchad",
          },
          gitgutter = true,
          lsp_trouble = true,
          which_key = true,
        },
      }
    end,
  },
}
