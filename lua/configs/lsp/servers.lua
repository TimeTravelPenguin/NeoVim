return function(on_attach, capabilities)
  return {
    html = {},
    cssls = {},
    docker_compose_language_service = {},
    jsonls = {},
    just = {
      filetypes = { "just" },
      root_dir = function(bufnr, on_dir)
        on_dir(vim.fs.root(bufnr, { ".git", "justfile" }))
      end,
      on_attach = on_attach,
      capabilities = capabilities,
    },
    -- Lean and Pest are configured by their plugin integrations.
    wgsl_analyzer = {},

    lua_ls = {
      on_init = function(client)
        local workspace = client.workspace_folders and client.workspace_folders[1]
        local path = workspace and workspace.name
        if path and (vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc")) then
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

    tinymist = require "configs.lsp.typst",

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
end
