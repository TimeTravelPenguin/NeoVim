-- Run after normal startup: nvim --headless -i NONE -n '+luafile scripts/formatting-smoke.lua'
local fixture_dir

local function check()
  local plugin = assert(require("lazy.core.config").plugins["conform.nvim"])
  assert(not plugin._.loaded, "Conform loaded before the first save; cold loading was not tested")
  assert(vim.fn.exists ":ToggleFormatOnSave" == 2, "Formatting toggle command is missing")

  local stylua = vim.fn.exepath "stylua"
  assert(stylua ~= "", "Installed StyLua is not on Neovim's PATH")
  local unformatted = "local  value={1,2,3}"
  local formatted = vim.fn.system({ stylua, "-" }, unformatted .. "\n"):gsub("\n$", "")
  assert(vim.v.shell_error == 0 and formatted ~= unformatted, "StyLua did not format the fixture")

  fixture_dir = vim.fn.tempname() .. "-formatting-smoke"
  vim.fn.mkdir(fixture_dir, "p")
  local notifications = {}
  local formatter_errors = {}
  local original_notify = vim.notify
  vim.notify = function(message, level)
    notifications[#notifications + 1] = tostring(message)

    if type(level) == "number" and level >= vim.log.levels.WARN then
      formatter_errors[#formatter_errors + 1] = tostring(message)
    end
  end

  local function make_buffer(name)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, fixture_dir .. "/" .. name .. ".lua")
    vim.api.nvim_buf_call(buf, function()
      -- Avoid starting language servers; the real CLI formatter is sufficient.
      vim.cmd "noautocmd setlocal filetype=lua"
    end)

    return buf
  end

  local first = make_buffer "first"
  local second = make_buffer "second"
  local writes = 0

  local function toggle(buf, bang)
    vim.api.nvim_set_current_buf(buf)
    vim.cmd(bang and "ToggleFormatOnSave!" or "ToggleFormatOnSave")

    return notifications[#notifications]
  end

  local function save(buf, should_format, label)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { unformatted })
    vim.cmd "silent write!"
    local actual = table.concat(vim.fn.readfile(vim.api.nvim_buf_get_name(buf)), "\n")
    local memory = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    local expected = should_format and formatted or unformatted
    assert(actual == expected, label .. ": wrong content saved to disk: " .. actual)
    assert(memory == expected, label .. ": buffer and disk contents differ")

    if writes == 0 then
      assert(plugin._.loaded, "The first save did not load Conform through Lazy")
      assert(require("conform").get_formatter_info("stylua", buf).available, "StyLua is unavailable to Conform")
    end

    writes = writes + 1
  end

  local function save_both(first_enabled, second_enabled, label)
    save(first, first_enabled, label .. "/first")
    save(second, second_enabled, label .. "/second")
  end

  vim.g.disable_autoformat = nil
  vim.b[first].disable_autoformat = nil
  vim.b[second].disable_autoformat = nil
  save_both(true, true, "default enabled")

  assert(toggle(first, false) == "Autoformat globally: false")
  assert(vim.b[first].disable_autoformat == nil and vim.b[second].disable_autoformat == nil)
  save_both(false, false, "global disabled")

  assert(toggle(second, false) == "Autoformat globally: true")
  save_both(true, true, "global reenabled")

  assert(toggle(first, true) == "Autoformat for this buffer: false")
  assert(not vim.g.disable_autoformat and vim.b[second].disable_autoformat == nil)
  save_both(false, true, "first buffer disabled")

  assert(toggle(first, true) == "Autoformat for this buffer: true")
  save_both(true, true, "first buffer reenabled")

  toggle(first, true)
  toggle(first, false)
  assert(vim.b[first].disable_autoformat and vim.g.disable_autoformat)
  save_both(false, false, "global overrides buffer settings")

  assert(toggle(first, false) == "Autoformat globally: true")
  assert(vim.b[first].disable_autoformat, "Global toggle reset the independent buffer setting")
  save_both(false, true, "global enabled with first buffer disabled")

  toggle(first, false)
  assert(toggle(first, true) == "Autoformat for this buffer: true")
  assert(vim.g.disable_autoformat and not vim.b[first].disable_autoformat)
  save_both(false, false, "buffer enabled with global disabled")

  toggle(second, false)
  save_both(true, true, "both restrictions cleared")
  assert(writes == 18, "The complete save matrix was not exercised")
  assert(#formatter_errors == 0, "Formatter errors: " .. table.concat(formatter_errors, "; "))

  for _, buf in ipairs({ first, second }) do
    local path = vim.api.nvim_buf_get_name(buf)
    vim.api.nvim_buf_delete(buf, { force = true })
    assert(vim.fn.delete(path) == 0, "Could not remove temporary fixture: " .. path)
  end

  assert(vim.fn.delete(fixture_dir, "d") == 0, "Could not remove temporary fixture directory")
  vim.notify = original_notify
  print("PASS: Lazy first-save activation, real StyLua formatting, global/buffer toggles, precedence, and 18 writes verified on disk")
end

vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)

  if not ok then
    io.stderr:write(err .. "\n")

    if fixture_dir then
      io.stderr:write("Temporary fixtures retained: " .. fixture_dir .. "\n")
    end

    vim.cmd "cquit 1"
    return
  end

  vim.cmd "qa!"
end, 100)
