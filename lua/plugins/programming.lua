return {
  {
    "danymat/neogen",
    opts = require "opts.neogen",
    config = function()
      require("neogen").setup { snippet_engine = "luasnip" }
    end,
  },
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap-python",
    },
    config = require "configs.venv-selector",
    event = "VeryLazy",
    keys = {
      { "<leader>vs", "<cmd>VenvSelect<cr>" },
      { "<leader>vc", "<cmd>VenvSelectCached<cr>" },
    },
  },
  {
    "folke/trouble.nvim",
    branch = "dev", -- IMPORTANT!
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
    dependencies = {
      {
        "folke/todo-comments.nvim",
        opts = {},
      },
    },
    opts = {},
    init = function()
      local map = vim.keymap.set

      map("n", "<leader>t", "<CMD>TroubleToggle<CR>", { desc = "Toggle diagnostics" })
      map("n", "<leader>td", "<CMD>TodoTrouble keywords=TODO,FIX,FIXME,BUG,TEST,NOTE<CR>", { desc = "Todo/Fix/Fixme" })
    end,
  },
}
