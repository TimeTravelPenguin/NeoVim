return {
  -- File formatting
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require "configs.conform"
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  {
    "williamboman/mason.nvim",
    opts = function()
      require "opts.mason"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
      require "opts.treesitter"
    end,
  },
}
