local filetype_textwidths = {
  rust = 80,
  typst = 90,
}

local aug = vim.api.nvim_create_augroup("SetTextWidthPerFT", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = vim.tbl_keys(filetype_textwidths), -- matches filetype names
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    local tw = filetype_textwidths[ft]
    if tw then
      -- any of these set the buffer-local option; pick your style:
      -- vim.opt_local.textwidth = tw
      -- vim.bo[ev.buf].textwidth = tw
      vim.api.nvim_set_option_value("textwidth", tw, { buf = ev.buf })
    end
  end,
})
