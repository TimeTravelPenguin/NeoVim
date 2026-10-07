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

      settings = function(workspace_root, default_settings)
        local settings = vim.deepcopy(default_settings)
        local project_root = vim.fs.root(vim.fn.getcwd(), { "Cargo.toml" })

        if not project_root or not workspace_root then
          return settings
        end

        local function cargo_command(command)
          return {
            "sh",
            "-c",
            'cd "$1" && exec cargo "$2" --message-format=json --keep-going',
            "nvim-cargo",
            project_root,
            command,
          }
        end

        local rust_analyzer = settings["rust-analyzer"]
        local cargo = rust_analyzer.cargo
        local config_dir = project_root

        -- Cargo itself merges the full hierarchy; analysis needs the member's config.
        while not cargo.configPath and config_dir and config_dir ~= workspace_root do
          for _, config_name in ipairs { "config", "config.toml" } do
            local config_path = config_dir .. "/.cargo/" .. config_name

            if vim.uv.fs_stat(config_path) then
              cargo.configPath = config_path
              break
            end
          end

          local parent_dir = vim.fs.dirname(config_dir)
          config_dir = parent_dir ~= config_dir and parent_dir or nil
        end

        cargo.buildScripts = cargo.buildScripts or {}

        if not cargo.buildScripts.overrideCommand then
          cargo.buildScripts.overrideCommand = cargo_command "check"
          cargo.buildScripts.invocationStrategy = cargo.buildScripts.invocationStrategy or "once"
        end

        local check = rust_analyzer.check

        if not check.overrideCommand then
          check.overrideCommand = cargo_command "clippy"
          check.invocationStrategy = check.invocationStrategy or "once"
        end

        return settings
      end,

      default_settings = {
        ["rust-analyzer"] = {
          cargo = {},

          check = {
            command = "clippy",
          },
        },
      },
    },

    dap = {},
  }
end
