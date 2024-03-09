return {
  {
    "andweeb/presence.nvim",
    opts = function()
      require("presence").setup {
        -- General options
        auto_update = true,
        main_image = "neovim", -- Main image display (either "neovim" or "file")
        enable_line_number = false,
        blacklist = {},
        -- Configure Rich Presence button(s),
        -- either a boolean to enable/disable,
        -- a static table {{ label = "<label>", url = "<url>" }, ...},
        -- or a function(buffer: string, repo_url: string|nil): table
        buttons = true,
        file_assets = {},
        show_time = true,

        -- Rich Presence text options
        editing_text = "Editing %s",
        reading_text = "Reading %s",
      }
    end,
    lazy = false,
  },
}
