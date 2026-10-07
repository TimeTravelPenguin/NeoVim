return function(on_attach)
  on_attach = on_attach or function(client, bufnr)
    require("nvchad.configs.lspconfig").on_attach(client, bufnr)
  end

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
end
