vim.opt.fillchars:append { diff = "╱" }

require("diffview").setup {
  enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
  hooks = {
    diff_buf_read = function(bufnr)
      -- Change local options in diff buffers
      vim.opt_local.wrap = false
      vim.opt_local.list = false
      vim.opt_local.colorcolumn = { 80 }
    end,
    view_opened = function(view)
      print(("A new %s was opened on tab page %d!"):format(view.class:name(), view.tabpage))
    end,
  },
}
