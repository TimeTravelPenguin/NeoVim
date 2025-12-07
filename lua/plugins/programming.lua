return {
  {
    "danymat/neogen",
    config = function()
      require("neogen").setup {
        snippet_engine = "luasnip",
        languages = {
          python = {
            template = {
              annotation_convention = "numpydoc",
            },
          },
        },
        lua = {
          template = {
            annotation_convention = "emmylua",
          },
        },
        sh = {
          template = {
            annotation_convention = "google_bash",
          },
        },
      }
    end,
    keys = {
      { "<leader>ng", "<cmd>lua require('neogen').generate()<cr>", desc = "Neogen generate" },
      { "<leader>nf", "<cmd>lua require('neogen').generate({ type = 'func' })<cr>", desc = "Neogen generate function" },
      { "<leader>nc", "<cmd>lua require('neogen').generate({ type = 'class' })<cr>", desc = "Neogen generate class" },
      { "<leader>nt", "<cmd>lua require('neogen').generate({ type = 'type' })<cr>", desc = "Neogen generate type" },
      { "<leader>nF", "<cmd>lua require('neogen').generate({ type = 'file' })<cr>", desc = "Neogen generate file" },
    },
  },

  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-dap",
      "mfussenegger/nvim-dap-python",
      { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    opts = {
      options = {
        on_telescope_result_callback = function(filename)
          return filename:gsub(os.getenv "HOME", "~"):gsub("/bin/python", "")
        end,
      },
    },
    -- ft = "python",
    lazy = false,
    keys = {
      { "<leader>vs", "<cmd>VenvSelect<cr>" },
      { "<leader>vc", "<cmd>VenvSelectCached<cr>" },
    },
  },

  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
    cmd = { "Trouble", "TroubleToggle", "TodoTrouble" },
    keys = {
      {
        "<leader>tr",
        "<cmd>Trouble diagnostics toggle focus=true<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>tR",
        "<cmd>Trouble diagnostics_current_buffer toggle focus=true<cr>",
        desc = "Diagnostics Current Buffer (Trouble)",
      },
      {
        "<leader>tp",
        "<cmd>Trouble preview_float toggle focus=true<cr>",
        desc = "Diagnostics Popup (Trouble)",
      },
      {
        "<leader>tt",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>ts",
        "<cmd>Trouble symbols toggle focus=false win.position=bottom<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>tl",
        "<cmd>Trouble lsp toggle focus=false win.position=bottom<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>tL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>tQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
    opts = {
      modes = {
        preview_float = {
          mode = "diagnostics",
          preview = {
            type = "float",
            relative = "editor",
            border = "rounded",
            title = "Preview",
            title_pos = "center",
            position = { 0, -2 },
            size = { width = 0.5, height = 0.4 },
            zindex = 200,
          },
        },
        diagnostics_current_buffer = {
          mode = "diagnostics", -- inherit from diagnostics mode
          filter = {
            any = {
              buf = 0, -- current buffer
              {
                severity = vim.diagnostic.severity.ERROR, -- errors only
                -- limit to files in the current project
                function(item)
                  return item.filename:find((vim.loop or vim.uv).cwd(), 1, true)
                end,
              },
            },
          },
        },
      },
    },
  },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/trouble.nvim" },
    lazy = false,
    cmd = { "TodoQuickFix", "TodoTrouble", "TodoTelescope" },
    config = function()
      require("todo-comments").setup()

      vim.keymap.set("n", "]c", function()
        require("todo-comments").jump_next()
      end, { desc = "Next todo comment" })

      vim.keymap.set("n", "[c", function()
        require("todo-comments").jump_prev()
      end, { desc = "Previous todo comment" })
    end,
  },

  {
    "mrcjkb/haskell-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    version = "^4",
    lazy = false, -- This plugin is already lazy
  },
}
