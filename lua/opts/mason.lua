local options = {
  ensure_installed = {
    -- General
    "html-lsp",
    "css-lsp",
    "prettier",
    "typos",
    -- Python
    "codespell",
    "debugpy",
    "docformatter",
    "misspell",
    "mypy",
    "pylint",
    "pyright",
    "ruff",
    "ruff-lsp",
    -- Haskell
    "haskell-debug-adapter",
    "haskell-language-server",
    "fourmolu",
    -- Rust,
    "rust-analyzer",
    "codelldb", -- debugger
    -- Lua
    "lua-language-server",
    "luacheck",
    "luaformatter",
    "stylua",
    -- Bash / sh
    "shfmt",
    "shellcheck",
    -- Other
    "matlab-language-server",
  },
}

require("mason").setup(options)
