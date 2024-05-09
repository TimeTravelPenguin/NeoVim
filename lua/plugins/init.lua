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
      require "configs.lspconfig"
    end,
  },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
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
