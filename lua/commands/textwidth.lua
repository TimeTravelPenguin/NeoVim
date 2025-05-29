-- Define a table mapping filetypes to their desired textwidth values
local filetype_textwidths = {
  rust = 80,
}

-- Create an autocommand that applies to all filetypes defined in the table keys
vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_keys(filetype_textwidths),
  callback = function()
    local ft = vim.bo.filetype
    local tw = filetype_textwidths[ft]
    if tw then
      vim.opt_local.textwidth = tw
    end
  end,
})
