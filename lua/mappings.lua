require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jj", "<ESC>", { desc = "Exit insert mode" })

map("n", "<C-s>", "<CMD> w <CR>", { desc = "Save file" })
map({ "i", "v" }, "<C-s>", "<ESC> <CMD> w <CR>", { desc = "Save file and exit mode" })
