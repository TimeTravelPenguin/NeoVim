return {
  -- File formatting
  {
    "stevearc/conform.nvim",
    config = function()
      require "configs.conform"
    end,
  },

  {
    "williamboman/mason.nvim",
    opts = require "opts.mason",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = require "opts.treesitter",
  },

  {
    "folke/neodev.nvim",
    event = "BufEnter",
    -- Setup in configs/lspconfig.lua
  },

  {
    "nvimtools/none-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require "configs.none-ls"
    end,
  },
}
