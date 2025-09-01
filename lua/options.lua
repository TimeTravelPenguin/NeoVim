require "nvchad.options"

local o = vim.o
local opt = vim.opt

o.cursorlineopt = 'both'
opt.relativenumber = true

-- o.textwidth = 80

require "commands.textwidth"
require "commands.saving"
