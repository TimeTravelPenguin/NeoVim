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

local servers = require("configs.lsp.servers")(on_attach, capabilities)

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
