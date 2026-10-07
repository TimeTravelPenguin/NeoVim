return {
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
