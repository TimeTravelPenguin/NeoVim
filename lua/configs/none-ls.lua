local null_ls = require "null-ls"

local builtins = null_ls.builtins
local formatting = builtins.formatting
local code_actions = builtins.code_actions
local completion = builtins.completion
local diagnostics = builtins.diagnostics

null_ls.setup {
  sources = {
    diagnostics.mypy,
    diagnostics.pylint,
  },
}
