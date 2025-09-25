return {
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },

  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
  },

  {
    "zbirenbaum/copilot.lua",
    event = { "InsertEnter" },
    cmd = { "Copilot" },
    config = function()
      require("copilot").setup {
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = false,
            accept_line = "<C-l>",
          },
        },
      }
    end,
  },

  {
    "chomosuke/typst-preview.nvim",
    lazy = false,
    version = "1.*",
    config = function()
      require("typst-preview").setup {
        dependencies_bin = { ["tinymist"] = "tinymist" },
        -- extra_args = { "--input=flavor=mocha" },
      }
    end,
  },

  -- Lines have gaps. Maybe this? https://github.com/chikko80/error-lens.nvim/issues/11
  -- {
  --   "chikko80/error-lens.nvim",
  --   event = "BufRead",
  --   dependencies = {
  --     "nvim-telescope/telescope.nvim",
  --   },
  --   opts = {
  --     -- your options go here
  --   },
  -- },

  {
    "fei6409/log-highlight.nvim",
    config = function()
      require("log-highlight").setup {}
    end,
    lazy = false,
  },

  {
    "susensio/magic-bang.nvim",
    config = true,
    event = "BufNewFile",
    cmd = "Bang",
  },
}
