return {
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-dap",
      "mfussenegger/nvim-dap-python",
      { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
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
}
