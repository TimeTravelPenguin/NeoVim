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
  -- Plugin configuration
  tools = {},
  -- LSP configuration
  server = {
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
  },
}

local servers = {
  html = {},
  cssls = {},
  docker_compose_language_service = {},
  jsonls = {},
  leanls = {},
  ["pest-vim"] = {},

  lua_ls = {
    on_init = function(client)
      on_init(client)

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
    on_attach = function(client, bufnr)
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
    end,
    filetypes = { "python" },
    trace = "verbose",
    init_options = {
      settings = {
        logLevel = "error",
      },
    },
  },

  tinymist = {
    on_attach = function(client, bufnr)
      on_attach(client, bufnr)

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
          notify("Updated pinned main to " .. filename, vim.log.levels.INFO, { title = "Updating pinned main" }).events.close()
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
    root_dir = function(bufnr, on_dir)
      return on_dir(vim.fn.getcwd())
    end,
    settings = {
      exportPdf = "onSave",
      outputPath = "$dir/$name",
      formatterMode = "typstyle",
      formatterPrintWidth = 80,
      semanticTokens = "disabled",
    },
  },

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

  harper_ls = {
    settings = {
      ["harper-ls"] = {
        userDictPath = "",
        workspaceDictPath = "",
        fileDictPath = "",
        linters = {
          SpellCheck = true,
          SpelledNumbers = false,
          AnA = true,
          SentenceCapitalization = true,
          UnclosedQuotes = true,
          WrongQuotes = false,
          LongSentences = true,
          RepeatedWords = true,
          Spaces = true,
          Matcher = true,
          CorrectNumberSuffix = true,
        },
        codeActions = {
          ForceStable = false,
        },
        markdown = {
          IgnoreLinkTitle = false,
        },
        diagnosticSeverity = "hint",
        isolateEnglish = false,
        dialect = "Australian",
        maxFileLength = 120000,
        ignoredLintsPath = {},
      },
    },
  },
}

for name, opts in pairs(servers) do
  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end
