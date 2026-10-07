local tinymist_target = "paged"

local target_settings = {
  paged = {
    exportTarget = "paged",
    typstExtraArgs = {},
  },
  html = {
    exportTarget = "html",
    typstExtraArgs = { "--features=html" },
  },
  bundle = {
    exportTarget = "bundle",
    typstExtraArgs = { "--features=bundle,html" },
  },
}

local function tinymist_settings()
  return vim.tbl_deep_extend("force", {
    exportPdf = "onSave",
    outputPath = "$dir/$name",
    formatterMode = "typstyle",
    formatterPrintWidth = 80,
    semanticTokens = "disable",
  }, target_settings[tinymist_target])
end

local function restart_tinymist()
  local settings = tinymist_settings()

  -- This is what Neovim's native `:lsp restart tinymist` will read
  -- when it starts the new Tinymist client.
  if vim.lsp.config then
    pcall(vim.lsp.config, "tinymist", {
      settings = settings,
    })
  end

  -- Keep the current client config in sync too. This helps older paths
  -- and makes inspection/debugging less confusing.
  for _, client in ipairs(vim.lsp.get_clients { name = "tinymist" }) do
    client.config.settings = vim.deepcopy(settings)
  end

  if pcall(vim.cmd, "lsp restart tinymist") then
    return
  end

  pcall(vim.cmd, "LspRestart tinymist")
end

local function set_tinymist_target(target)
  if not target_settings[target] then
    return
  end

  tinymist_target = target
  restart_tinymist()
  vim.notify("Tinymist target: " .. target)
end

return {
  settings = tinymist_settings(),

  -- Important: used when the server is started again.
  on_new_config = function(config)
    config.settings = tinymist_settings()
  end,

  root_dir = function(bufnr, on_dir)
    return on_dir(vim.fn.getcwd())
  end,

  on_attach = function(client, bufnr)
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
    end, { force = true })

    vim.api.nvim_create_user_command("TinymistTarget", function()
      vim.ui.select({ "paged", "html", "bundle" }, {
        prompt = "Tinymist target",
      }, function(choice)
        if choice then
          set_tinymist_target(choice)
        end
      end)
    end, { force = true })

    map("n", "<leader>bt", function()
      vim.cmd.TinymistTarget()
    end, { desc = "tinymist: Set target", noremap = true, buffer = bufnr })
  end,
}
