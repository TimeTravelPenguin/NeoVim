local treesitter = {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  event = function()
    return {}
  end,
  cmd = function()
    return {}
  end,
  build = ":TSUpdate",
  opts = require "opts.treesitter",
  config = function(_, opts)
    require("configs.treesitter").setup(opts)
  end,
}

-- The legacy editor uses its own plugin directory and lockfile.
if vim.fn.has "nvim-0.12" == 0 then
  treesitter.branch = "master"
  treesitter.commit = "cf12346a3414fa1b06af75c79faebe7f76df080a"
end

return { treesitter }
