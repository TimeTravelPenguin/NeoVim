function vim_o_toggle(opt, on, off, name)
  local message = name
  if vim.o[opt] == off then
    vim.o[opt] = on
    message = message .. " Enabled"
  else
    vim.o[opt] = off
    message = message .. " Disabled"
  end
  vim.notify(message)
end

function vim_opt_toggle(opt, on, off, name)
  local message = name
  if vim.opt[opt]:get() == off then
    vim.opt[opt] = on
    message = message .. " Enabled"
  else
    vim.opt[opt] = off
    message = message .. " Disabled"
  end
  vim.notify(message)
end
