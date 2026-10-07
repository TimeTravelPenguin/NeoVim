-- Run after normal startup: nvim --headless -i NONE -n '+luafile scripts/smoke.lua'
local function check()
  local profile = require "configs.profile"
  local lazy_config = require "lazy.core.config"
  local lock = vim.json.decode(table.concat(vim.fn.readfile(profile.lockfile), "\n"))

  for name in pairs(lock) do
    assert(lazy_config.plugins[name], "Plugin missing from resolved configuration: " .. name)
  end

  -- Exercise Lazy's real lock writer without touching the user's lockfile.
  local lock_manager = require "lazy.manage.lock"
  local original_lockfile = lazy_config.options.lockfile
  local original_lock = lock_manager.lock
  local original_loaded = lock_manager._loaded
  local temporary_lockfile = vim.fn.tempname() .. ".json"
  lazy_config.options.lockfile = temporary_lockfile
  lock_manager._loaded = false
  local saved, save_error = pcall(lock_manager.update)
  lazy_config.options.lockfile = original_lockfile
  lock_manager.lock = original_lock
  lock_manager._loaded = original_loaded

  if not saved then
    vim.fn.delete(temporary_lockfile)
    error("Lazy lock persistence failed: " .. tostring(save_error))
  end

  local saved_lock = vim.json.decode(table.concat(vim.fn.readfile(temporary_lockfile), "\n"))
  vim.fn.delete(temporary_lockfile)

  for name, entry in pairs(lock) do
    assert(saved_lock[name] and saved_lock[name].commit == entry.commit, "Lock writer changed a plugin revision: " .. name)
  end

  for _, path in ipairs(vim.fn.glob(vim.fn.stdpath("config") .. "/**/*.lua", false, true)) do
    assert(loadfile(path), "Invalid Lua: " .. path)
  end

  local command = vim.api.nvim_get_commands({}).TSInstallAll
  assert(command and command.definition == "Install the configured Treesitter parsers", "Wrong TSInstallAll owner")

  if profile.modern then
    local legacy_site = vim.fn.stdpath "data" .. "/site"

    for _, path in ipairs(vim.opt.rtp:get()) do
      assert(path ~= legacy_site and path ~= legacy_site .. "/after", "Legacy parser runtime leaked into 0.12")
    end

    local languages = vim.list_extend(vim.deepcopy(require("opts.treesitter").ensure_installed), { "d2" })

    for _, language in ipairs(languages) do
      assert(vim.treesitter.language.add(language), "Cannot load parser: " .. language)
      vim.treesitter.query.get(language, "highlights")
    end

    local markdown = {
      "# Migration smoke test",
      "",
      "```lua",
      "local message = 'hello'",
      "print(message)",
      "```",
    }

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, markdown)
    vim.bo[buf].filetype = "markdown"
    local parser = vim.treesitter.get_parser(buf, "markdown")
    parser:parse(true)
    local injected_lua = false

    parser:for_each_tree(function(tree, language_tree)
      vim.treesitter.get_node_text(tree:root(), buf)
      injected_lua = injected_lua or language_tree:lang() == "lua"
    end)

    assert(injected_lua, "Markdown fenced Lua injection was not parsed")
    vim.treesitter.start(buf)

    require("telescope.previewers.utils").highlighter(buf, "markdown", { preview = { treesitter = true } })
    assert(vim.treesitter.highlighter.active[buf], "Telescope preview did not attach a Treesitter highlighter")

    local _, win = vim.lsp.util.open_floating_preview(markdown, "markdown", { focus = false })
    assert(vim.api.nvim_win_is_valid(win), "Markdown LSP preview failed")
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })

    -- Exercise the command without making another network/install request.
    local treesitter = require "nvim-treesitter"
    local install = treesitter.install
    local requested
    treesitter.install = function(selected)
      requested = selected
    end

    vim.cmd "TSInstallAll"
    treesitter.install = install
    assert(requested and #requested == 43 and vim.tbl_contains(requested, "d2"), "Incomplete parser install command")
  else
    local installer = require "nvim-treesitter.install"
    local ensure_installed = installer.ensure_installed
    local requested
    installer.ensure_installed = function(selected)
      requested = selected
    end

    vim.cmd "TSInstallAll"
    installer.ensure_installed = ensure_installed
    assert(requested and #requested == 42, "Legacy parser install command did not retain its language list")
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "FilePost", modeline = false })
  local servers = require("configs.lsp.servers")()

  for name in pairs(servers) do
    assert(vim.lsp.config[name] and vim.lsp.config[name].cmd, "LSP command missing: " .. name)
  end

  assert(vim.lsp.config.pest_ls.cmd, "Pest integration did not configure its LSP")
  assert(vim.lsp.config.copilot_ls.cmd, "Copilot runtime was not available when enabled")
  local common = "plugin preservation, lock persistence, Lua syntax, install command, LSP registration"
  local modern = ", runtime isolation, parser/query loading, Markdown injections, Telescope/LSP previews"
  print("PASS: " .. common .. (profile.modern and modern or ", legacy 0.11 startup"))
end

vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)

  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd "cquit 1"
    return
  end

  vim.cmd "qa!"
end, 100)
