local options = {}

options.formatters_by_ft = {
  lua = { "stylua" },
  sh = { "shellcheck", "shellharden", "shfmt" },
  bash = { "shellcheck", "shellharden", "shfmt" },
  -- python = { "ruff_format", "ruff_fix", "ruff_organize_imports" },
  json = { "prettier" },
  markdown = { "prettier" },
  html = { "prettier" },
  css = { "prettier" },
  xml = { "xmllint" },
  yaml = { "prettier" },
  toml = { "taplo" },
  javascript = { "prettier" },
  haskell = { "fourmolu" },
}

options.format_on_save = function(bufnr)
  -- Disable with a global or buffer-local variable
  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
    return
  end
  return { timeout_ms = 500, lsp_fallback = true }
end

options.formatters = {
  shfmt = {
    prepend_args = { "-i", "2" },
  },
}

require("conform").setup(options)
