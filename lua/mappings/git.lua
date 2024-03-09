local map = vim.keymap.set

map("n", "<leader>dvo", ":DiffviewOpen<CR>", { desc = "Open Diffview" })
map("n", "<leader>dvc", ":DiffviewClose<CR>", { desc = "Close Diffview" })
