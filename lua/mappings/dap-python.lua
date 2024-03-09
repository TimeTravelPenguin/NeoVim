local map = vim.keymap.set

map(
  "n",
  "<leader>dn",
  ":lua require('dap-python').test_method()<CR>",
  { desc = "python-dap: Test method", noremap = true, silent = true }
)

map(
  "n",
  "<leader>df",
  ":lua require('dap-python').test_class()<CR>",
  { desc = "python-dap: Test class", noremap = true, silent = true }
)

map(
  "v",
  "<leader>ds",
  "<ESC>:lua require('dap-python').debug_selection()<CR>",
  { desc = "python-dap: Debug selected", noremap = true, silent = true }
)
