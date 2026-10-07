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

}
