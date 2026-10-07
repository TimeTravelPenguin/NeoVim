return {
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
}
