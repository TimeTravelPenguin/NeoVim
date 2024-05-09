return {
  -- File formatting
  {
    "stevearc/conform.nvim",
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
    "folke/neodev.nvim",
    event = "BufEnter",
    -- Setup in configs/lspconfig.lua
  },

  {
    "williamboman/mason.nvim",
    opts = require "opts.mason",
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = require "opts.treesitter",
  },
}
