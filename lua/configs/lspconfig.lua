require("nvchad.configs.lspconfig").defaults()

local configs = require "nvchad.configs.lspconfig"
local on_attach = configs.on_attach
local on_init = configs.on_init
local capabilities = configs.capabilities

-- Common bits you used everywhere
local common = {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
}

require("pest-vim").setup {}

vim.g.rustaceanvim = {
  tools = {},

  server = {
    on_attach = function(client, bufnr)
      on_attach(client, bufnr)

      vim.keymap.set("n", "<leader>ca", function()
        vim.cmd.RustLsp "codeAction"
      end, { silent = true, buffer = bufnr })

      vim.keymap.set("n", "K", function()
        vim.cmd.RustLsp { "hover", "actions" }
      end, { silent = true, buffer = bufnr })
    end,

    default_settings = {
      ["rust-analyzer"] = {
        cargo = {
          features = "all",
        },

        check = {
          command = "clippy",
        },
      },
    },
  },

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
  },
}

local servers = {
  html = {},
  cssls = {},
  docker_compose_language_service = {},
  jsonls = {},
  just = {
    filetypes = { "just" },
    root_dir = function(fname)
      return vim.fs.root(fname, { ".git", "justfile" })
    end,
    on_attach = on_attach,
    capabilities = capabilities,
  },
  leanls = {},
  ["pest-vim"] = {},
  wgsl_analyzer = {},

  lua_ls = {
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
  },

  texlab = {
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
  },

  pyright = {
    filetypes = { "python" },
    settings = {},
  },

  ruff = {
    filetypes = { "python" },
    trace = "verbose",
    init_options = {
      settings = {
        logLevel = "error",
        lineLength = 80,
      },
    },
  },

  tinymist = require "configs.lspconfig.typst",

  typos_lsp = {
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
  },

  ["harper-ls"] = {
    settings = {
      ["harper-ls"] = {
        linters = {
          SentenceCapitalization = false,
          SpellCheck = false,
        },
        codeActions = {
          ForceStable = false,
        },
        dialect = "Australian",
      },
    },
  },

  tombi = {
    cmd = { "tombi", "lsp" },
    filetypes = { "toml" },
    root_markers = { "tombi.toml", "pyproject.toml", ".git" },
  },
}

for name, opts in pairs(servers) do
  -- If opts contains on_attach or on_init, wrap them both in a function
  -- if opts.on_attach then
  --   local on_attach_fn = opts.on_attach
  --   opts.on_attach = function(client, bufnr)
  --     on_attach(client, bufnr)
  --     on_attach_fn(client, bufnr)
  --   end
  -- else
  --   opts.on_attach = common.on_attach
  -- end

  -- if opts.on_init then
  --   local on_init_fn = opts.on_init
  --   opts.on_init = function(client)
  --     on_init(client)
  --     on_init_fn(client)
  --   end
  -- else
  --   opts.on_init = common.on_init
  -- end

  -- opts.capabilities = vim.tbl_deep_extend("force", common.capabilities, opts.capabilities or {})

  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end

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

-- Pin main.typ automatically when Tinymist attaches
local grp = vim.api.nvim_create_augroup("tinymist_pin_main", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = grp,
  callback = function(args)
    local callback_client = vim.lsp.get_client_by_id(args.data.client_id)

    if not callback_client or callback_client.name ~= "tinymist" then
      return
    end

    local path = vim.api.nvim_buf_get_name(args.buf)
    local tail = (vim.fs and vim.fs.basename) and vim.fs.basename(path) or vim.fn.fnamemodify(path, ":t")

    if tail ~= "main.typ" then
      return
    end

    -- Tinymist docs recommend this command for pinning the *current* file
    callback_client:exec_cmd({
      title = "Pin main.typ",
      command = "tinymist.pinMain",
      arguments = { args.file },
    }, { bufnr = args.buf })

    pcall(function()
      require "notify"("Pinned main: " .. tail, "info", { title = "Tinymist" })
    end)
  end,
})
