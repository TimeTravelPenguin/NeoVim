local options = {}

options.formatters_by_ft = {
  lua = { "stylua" },
  sh = { "prettier", "shellcheck", "shellharden", "shfmt" },
  bash = { "beautysh", "shellcheck", "shellcheck", "shellharden", "shfmt" },
  python = { "ruff_format", "ruff_fix" },
  json = { "prettier" },
  markdown = { "prettier" },
  html = { "prettier" },
  css = { "prettier" },
  xml = { "prettier", "xmllint" },
  yaml = { "prettier", "yamlfix", "yamlfmt" },
  toml = { "prettier" },
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
  prettier = {
    options = {
      -- Use a specific prettier parser for a filetype
      -- Otherwise, prettier will try to infer the parser from the file name
      ft_parsers = {
        toml = "toml",
        xml = "xml",
      },
    },
  },
}

require("conform").setup(options)
