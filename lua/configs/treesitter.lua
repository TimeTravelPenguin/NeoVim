local M = {}

function M.register_commands(opts)
  vim.api.nvim_create_user_command("TSInstallAll", function()
    local treesitter = require "nvim-treesitter"

    if type(treesitter.install) == "function" then
      local languages = vim.list_extend(vim.deepcopy(opts.ensure_installed), { "d2" })
      treesitter.install(languages)
    else
      require("nvim-treesitter.install").ensure_installed(opts.ensure_installed)
    end
  end, { force = true, desc = "Install the configured Treesitter parsers" })
end

function M.setup(opts)
  local treesitter = require "nvim-treesitter"
  local is_main = type(treesitter.install) == "function"

  if vim.fn.has "nvim-0.12" == 1 then
    assert(
      is_main,
      "Neovim 0.12 requires nvim-treesitter main in its dedicated plugin directory and lockfile"
    )

    treesitter.setup {
      install_dir = require("configs.profile").parser_root,
    }
  else
    assert(
      not is_main,
      "nvim-treesitter main requires Neovim 0.12; use the separate Neovim 0.11 plugin directory and lockfile"
    )

    require("nvim-treesitter.configs").setup {}
  end

  M.register_commands(opts)
end

return M
