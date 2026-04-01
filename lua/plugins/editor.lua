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
    "copilotlsp-nvim/copilot-lsp",
    init = function()
      vim.g.copilot_nes_debounce = 500
      vim.lsp.enable "copilot_ls"

      vim.keymap.set("n", "<tab>", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local state = vim.b[bufnr].nes_state
        if state then
          -- Try to jump to the start of the suggestion edit.
          -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
          local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
            or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
          return nil
        else
          -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
          return "<C-i>"
        end
      end, { desc = "Accept Copilot NES suggestion", expr = true })

      -- Clear copilot suggestion with Esc if visible, otherwise preserve default Esc behavior
      vim.keymap.set("n", "<esc>", function()
        if not require("copilot-lsp.nes").clear() then
          -- fallback to other functionality
        end
      end, { desc = "Clear Copilot suggestion or fallback" })
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    requires = {
      "copilotlsp-nvim/copilot-lsp",
    },
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

  {
    "Wansmer/treesj",
    keys = { "<space>m", "<space>j", "<space>s" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("treesj").setup()
    end,
  },

  {
    "ravsii/tree-sitter-d2",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    version = "*",
    build = "make nvim-install",
    lazy = false,
  },

  { "nvim-mini/mini.icons", version = "*" },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    ft = { "markdown" },
    keys = {
      {
        "<leader>mt",
        function()
          require("render-markdown").toggle()
        end,
        ft = "markdown",
        desc = "RenderMarkdown toggle",
      },
      {
        "<leader>mb",
        function()
          require("render-markdown").buf_toggle()
        end,
        ft = "markdown",
        desc = "RenderMarkdown buffer toggle",
      },
    },
    config = function()
      -- https://github.com/MeanderingProgrammer/render-markdown.nvim
      require("render-markdown").setup {
        completions = { lsp = { enabled = true } },
        heading = { icons = {} },
        link = {
          enabled = false,
        },
      }
    end,
  },
}
