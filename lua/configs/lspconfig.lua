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
local servers = { "html", "cssls", "docker_compose_language_service", "jsonls", "leanls" }

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

require("pest-vim").setup {}

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

lspconfig.texlab.setup {
  settings = {
    texlab = {
      auxDirectory = ".",
      bibtexFormatter = "texlab",
      build = {
        args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
        executable = "latexmk",
        forwardSearchAfter = false,
        onSave = false,
      },
      chktex = {
        onEdit = false,
        onOpenAndSave = false,
      },
      diagnosticsDelay = 300,
      formatterLineLength = 120,
      forwardSearch = {
        args = {},
      },
      latexFormatter = "latexindent",
      latexindent = {
        modifyLineBreaks = false,
      },
    },
  },
}

-- Disable hover from Ruff in favor of Pyright
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    if client.name == "ruff" then
      -- Disable hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = "LSP: Disable hover capability from Ruff",
})

lspconfig.pyright.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  on_init = on_init,
  filetypes = { "python" },
  settings = {},
}

require("lspconfig").ruff.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  on_init = on_init,
  filetypes = { "python" },
  trace = "verbose",
  init_options = {
    settings = {
      logLevel = "error",
    },
  },
}

-- vim.api.nvim_create_autocmd({
--   "BufNewFile",
--   "BufRead",
-- }, {
--   pattern = "*.typ",
--   callback = function()
--     local buf = vim.api.nvim_get_current_buf()
--     vim.api.nvim_buf_set_option(buf, "filetype", "typst")
--   end,
-- })

-- Pin main.typ automatically when Tinymist attaches
local grp = vim.api.nvim_create_augroup("tinymist_pin_main", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = grp,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if not client or client.name ~= "tinymist" then
      return
    end

    local path = vim.api.nvim_buf_get_name(args.buf)
    local tail = (vim.fs and vim.fs.basename) and vim.fs.basename(path) or vim.fn.fnamemodify(path, ":t")

    if tail ~= "main.typ" then
      return
    end

    -- Tinymist docs recommend this command for pinning the *current* file
    client:exec_cmd({
      title = "Pin main.typ",
      command = "tinymist.pinMain",
      arguments = { args.file },
    }, { bufnr = args.buf })

    pcall(function()
      require "notify"("Pinned main: " .. tail, "info", { title = "Tinymist" })
    end)
  end,
})

lspconfig.tinymist.setup {
  on_init = on_init,
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)

    -- local file_name = vim.api.nvim_buf_get_name(bufnr)
    -- if file_name:match "main.typ$" then
    --   client:exec_cmd({
    --     command = "tinymist.pinMain",
    --     arguments = { file_name },
    --   }, { bufnr = bufnr })
    --
    --   vim.print("Updated pinned main to " .. file_name)
    -- end

    local map = vim.keymap.set

    map("n", "<leader>ba", function()
      client:exec_cmd({
        command = "tinymist.pinMain",
        arguments = { vim.api.nvim_buf_get_name(0) },
      }, { bufnr = bufnr })

      local async = require "plenary.async"
      local notify = require("notify").async
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")

      async.run(function()
        notify("Updated pinned main to " .. filename, "info", { title = "Updating pinned main" }).events.close()
      end)
    end, { desc = "tinymist: Pin buffer as main", noremap = true })

    map("n", "<leader>bd", function()
      client:exec_cmd({
        command = "tinymist.pinMain",
        arguments = { vim.v.null },
      }, { bufnr = bufnr })

      local async = require "plenary.async"
      local notify = require("notify").async
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")

      async.run(function()
        notify("Unpinned " .. filename, "info", { title = "Unpinning main" }).events.close()
      end)
    end, { desc = "tinymist: Unpin buffer as main", noremap = true })

    vim.api.nvim_create_user_command("OpenPdf", function()
      local filepath = vim.api.nvim_buf_get_name(0)
      if filepath:match "%.typ$" then
        os.execute("open " .. vim.fn.shellescape(filepath:gsub("%.typ$", ".pdf")))
        -- replace open with your preferred pdf viewer
        -- os.execute("zathura " .. vim.fn.shellescape(filepath:gsub("%.typ$", ".pdf")))
      end
    end, {})
  end,
  capabilities = capabilities,
  root_dir = function()
    return vim.fn.getcwd()
  end,
  settings = {
    exportPdf = "onSave",
    outputPath = "$dir/$name",
    formatterMode = "typstyle",
    formatterPrintWidth = 80,
    semanticTokens = "disabled",
  },
}

lspconfig.typos_lsp.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  -- Logging level of the language server. Logs appear in :LspLog. Defaults to error.
  cmd_env = { RUST_LOG = "error" },
  init_options = {
    -- Custom config. Used together with a config file found in the workspace or its parents,
    -- taking precedence for settings declared in both.
    -- Equivalent to the typos `--config` cli argument.
    -- config = "~/code/typos-lsp/crates/typos-lsp/tests/typos.toml",
    -- How typos are rendered in the editor, can be one of an Error, Warning, Info or Hint.
    -- Defaults to error.
    diagnosticSeverity = "Error",
  },
}

vim.g.rustaceanvim = {
  -- Plugin configuration
  tools = {},
  -- LSP configuration
  server = {
    on_init = on_init,
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      on_attach(client, bufnr)

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

vim.g.haskell_tools = {
  ---@type ToolsOpts
  tools = {
    repl = {
      prefer = "stack",
      auto_focus = true,
    },
  },
  ---@type HaskellLspClientOpts
  hls = {
    ---@param client number The LSP client ID.
    ---@param bufnr number The buffer number
    ---@param ht HaskellTools = require('haskell-tools')
    on_attach = function(client, bufnr, ht)
      on_attach(client, bufnr)

      local opts = { noremap = true, silent = true, buffer = bufnr }

      -- code lens
      map("n", "<leader>cl", vim.lsp.codelens.run, vim.tbl_extend("force", opts, { desc = "Run Code Lens" }))

      -- Hoogle search for the type signature of the definition under the cursor
      vim.keymap.set(
        "n",
        "<space>hs",
        ht.hoogle.hoogle_signature,
        vim.tbl_extend("force", opts, { desc = "Hoogle Signature" })
      )

      -- Evaluate all code snippets
      vim.keymap.set(
        "n",
        "<space>ea",
        ht.lsp.buf_eval_all,
        vim.tbl_extend("force", opts, { desc = "Evaluate All Code Snippets" })
      )

      -- Toggle a GHCi repl for the current package
      vim.keymap.set("n", "<leader>rr", ht.repl.toggle, vim.tbl_extend("force", opts, { desc = "Toggle GHCi Repl" }))

      -- Toggle a GHCi repl for the current buffer
      vim.keymap.set("n", "<leader>rf", function()
        ht.repl.toggle(vim.api.nvim_buf_get_name(0))
      end, vim.tbl_extend("force", opts, { desc = "Toggle GHCi Repl for Buffer" }))

      vim.keymap.set("n", "<leader>rq", ht.repl.quit, vim.tbl_extend("force", opts, { desc = "Quit GHCi Repl" }))
    end,
    capabilities = capabilities,
  },
}
