require "nvchad.mappings"
require "helpers"

local nomap = vim.keymap.del

nomap("n", "<leader>v")
nomap("n", "<leader>h")
nomap("n", "<leader>n")
nomap("n", "<leader>rn")
nomap("n", "<leader>th")

local map = vim.keymap.set

map("n", "j", "gj", { remap = false, desc = "Move down line" })
map("n", "k", "gk", { remap = false, desc = "Move up line" })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jj", "<ESC>", { desc = "Exit insert mode" })

map("v", ">", ">gv", { desc = "Indent selection" })
map("v", "<", "<gv", { desc = "Unindent selection" })

-- Remaps
map("n", "<leader>ln", "<cmd>set nu!<CR>", { desc = "Toggle Line number" })
map("n", "<leader>lrn", "<cmd>set rnu!<CR>", { desc = "Toggle Relative number" })
map("x", "p", "P", { silent = true, remap = false, desc = "Paste without yanking" })

map("n", "<C-s>", "<CMD> w <CR>", { desc = "Save file" })
map({ "i", "v" }, "<C-s>", "<ESC> <CMD> w <CR>", { desc = "Save file and exit mode" })

map({ "n", "v" }, "<C-u>", "<C-u>zz", { desc = "Half page up", remap = false })
map({ "n", "v" }, "<C-d>", "<C-d>zz", { desc = "Half page down", remap = false })

map("n", "<M-j>", ":m +1<CR>", { desc = "Move line down" })
map("n", "<M-k>", ":m -2<CR>", { desc = "Move line up" })

map("n", "<leader>ww", function()
  vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle Word Wrap" })

map({ "n", "i", "v" }, "<F1>", function()
  vim_o_toggle("colorcolumn", tostring(vim.o.textwidth), "", "Colorcolumn")
end, { desc = "Toggle Colorcolumn" })

map("n", "<leader>th", function()
  local enabled = vim.lsp.inlay_hint.is_enabled()
  vim.lsp.inlay_hint.enable(not enabled)
  -- Force update for all buffers to ensure consistency
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    -- if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") then
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_option_value("buflisted", { buf = buf }) then
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = buf })
    end
  end
end, { desc = "Toggle inlay hints" })

map("n", "<leader>tf", "<CMD> ToggleFormatOnSave <CR>", { desc = "Toggle autoformat-on-save" })

-- Blink on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Menu ui for neovim: Keyboard users
vim.keymap.set("n", "<C-t>", function()
  require("menu").open "default"
end, { desc = "Open menu" })

-- Menu ui for neovim: mouse users + nvimtree users
vim.keymap.set("n", "<RightMouse>", function()
  vim.cmd.exec '"normal! \\<RightMouse>"'

  local options = vim.bo.ft == "NvimTree" and "nvimtree" or "default"
  require("menu").open(options, { mouse = true })
end, { desc = "Open menu" })

require "mappings.dap-python"
require "mappings.dap-ui"
require "mappings.git"
require "mappings.todo-comments"
require "mappings.copilot"
