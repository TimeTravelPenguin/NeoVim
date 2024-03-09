map = vim.keymap.set

map("n", "<leader>ct", ":TodoTrouble toggle<CR>", { desc = "Todo (Trouble)" })
map("n", "<leader>cq", ":TodoQuickFix<CR>", { desc = "Todo (Quickfix)" })
map("n", "<leader>cf", ":TodoTelescope<CR>", { desc = "Todo (Telescope)" })
