local map = vim.keymap.set

map("n", "<Leader>df", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.frames)
end, { desc = "DAP: Frames" })

map("n", "<Leader>ds", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.scopes)
end, { desc = "DAP: Scopes" })

map({ "n", "v" }, "<Leader>dh", require("dap.ui.widgets").hover, { desc = "DAP: Hover" })

map({ "n", "v" }, "<Leader>dp", require("dap.ui.widgets").preview, { desc = "DAP: Preview" })

map({ "n", "v" }, "<leader>dx", require("dapui").close, { desc = "DAP: Close" })
