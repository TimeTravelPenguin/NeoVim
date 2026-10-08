vim.api.nvim_create_user_command("Hex", function(opts)
  local hex = opts.args:gsub("^0[xX]", "")

  if not hex:match "^%x+$" then
    vim.notify("Invalid hexadecimal line number", vim.log.levels.ERROR)
    return
  end

  local line = tonumber(hex, 16)
  local line_count = vim.api.nvim_buf_line_count(0)

  if not line or line < 1 or line > line_count then
    vim.notify("Line number must be between 1 and " .. line_count, vim.log.levels.ERROR)
    return
  end

  vim.cmd(tostring(line))
end, {
  nargs = 1,
  desc = "Jump to a hexadecimal line number",
})
