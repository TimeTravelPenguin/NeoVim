-- Command to toggle formatting on save
vim.api.nvim_create_user_command("ToggleFormatOnSave", function(args)
  if args.bang then
    -- ToggleFormatOnSave! will disable formatting just for this buffer
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify("Autoformat for this buffer: " .. tostring(not vim.b.disable_autoformat))
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("Autoformat globally: " .. tostring(not vim.g.disable_autoformat))
  end
end, {
  desc = "Toggle autoformat-on-save",
  bang = true,
})
