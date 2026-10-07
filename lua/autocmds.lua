require "nvchad.autocmds"

-- NvChad defines this command after plugin setup; replace it with our adapter.
require("configs.treesitter").register_commands(require "opts.treesitter")
