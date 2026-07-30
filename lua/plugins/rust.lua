return {
  {
    "mrcjkb/rustaceanvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
    },
    version = "^8", -- Recommended
    lazy = false, -- This plugin is already lazy
  },

  {
    "saecki/crates.nvim",
    tag = "stable",
    event = { "BufRead Cargo.toml" },
    config = function()
      require("crates").setup()
    end,
  },

  {
    -- "pest-parser/pest.vim",
    "https://github.com/TimeTravelPenguin/pest.vim",
    branch = "lspconfig-deprecation-fix",
  },
}
