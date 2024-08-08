require("nvchad.configs.lspconfig").defaults()

require("neodev").setup {
  library = {
    plugins = { "nvim-dap-ui" },
    types = true,
  },
}

local configs = require "nvchad.configs.lspconfig"
local on_attach = configs.on_attach
local on_init = configs.on_init
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "ruff", "docker_compose_language_service", "jsonls", "leanls" }

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

lspconfig.lua_ls.setup {
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
      return
    end

    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      runtime = {
        version = "LuaJIT",
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          -- Depending on the usage, you might want to add additional paths here.
          -- "${3rd}/luv/library"
          -- "${3rd}/busted/library",
        },
      },
    })
  end,
  settings = {
    Lua = {},
  },
}

lspconfig.pyright.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "python" },
  settings = {
    Python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
      },
      completion = {},
    },
  },
}

lspconfig.tinymist.setup {
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)

    local map = vim.keymap.set

    map("n", "<leader>ba", function()
      vim.lsp.buf.execute_command { command = "tinymist.pinMain", arguments = { vim.api.nvim_buf_get_name(0) } }
    end, { desc = "tinymist: Pin buffer as main", noremap = true })

    map("n", "<leader>bd", function()
      vim.lsp.buf.execute_command { command = "tinymist.pinMain", arguments = { nil } }
    end, { desc = "tinymist: Unpin buffer as main", noremap = true })
  end,
  capabilities = capabilities,
  single_file_support = true,
  root_dir = function()
    return vim.fn.getcwd()
  end,
  settings = {
    exportPdf = "onSave",
    preview = "enable",
    outputPath = "$dir/$name",
    formatterMode = "typstyle",
  },
}

vim.g.rustaceanvim = {
  -- Plugin configuration
  tools = {},
  -- LSP configuration
  server = {
    -- on_init = on_init,
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      on_attach(client, bufnr)

      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

      -- you can also put keymaps in here
      -- local bufnr = vim.api.nvim_get_current_buf()
      vim.keymap.set("n", "<leader>ca", function()
        vim.cmd.RustLsp "codeAction" -- supports rust-analyzer's grouping
        -- or vim.lsp.buf.codeAction() if you don't want grouping.
      end, { silent = true, buffer = bufnr })
    end,
    default_settings = {
      -- rust-analyzer language server configuration
      ["rust_analyzer"] = {
        cargo = {
          allFeatures = true,
        },
        checkOnSave = {
          command = "clippy",
        },
      },
    },
  },
  -- DAP configuration
  dap = {},
}
