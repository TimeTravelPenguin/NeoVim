return {
  {
    "NvChad/nvcommunity",
    { import = "nvcommunity.git.diffview", opts = {
      enhanced_diff_hl = false,
    } },
    { import = "nvcommunity.git.lazygit" },
    { import = "nvcommunity.git.neogit" },
    -- {
    --   import = "nvcommunity.completion.copilot",
    -- },
  },
}
