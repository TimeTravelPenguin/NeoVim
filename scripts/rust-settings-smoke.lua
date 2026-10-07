-- Run after normal startup: nvim --headless -i NONE -n '+luafile scripts/rust-settings-smoke.lua'
local fixture_dir
local original_cwd = vim.fn.getcwd()

local function check()
  local server = assert(vim.g.rustaceanvim.server, "Rust configuration was not initialized")
  local settings = assert(server.settings, "Rust settings callback is missing")
  local defaults = server.default_settings
  local original_defaults = vim.deepcopy(defaults)
  fixture_dir = vim.fn.tempname() .. "-rust-settings-smoke"
  local workspace = fixture_dir .. "/workspace 'quotes' \"double\" $(literal)"
  local intermediate = workspace .. "/nested"
  local project = intermediate .. "/member with spaces"

  local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    assert(vim.fn.writefile(lines, path) == 0, "Could not create fixture: " .. path)
  end

  local function analyze(root, options)
    local result = settings(root, options or defaults)
    assert(vim.deep_equal(defaults, original_defaults), "Default settings were mutated")

    return result["rust-analyzer"]
  end

  write(workspace .. "/Cargo.toml", { "[workspace]", 'members = ["nested/member with spaces"]' })
  write(project .. "/Cargo.toml", { "[package]", 'name = "fixture"', 'version = "0.1.0"' })
  write(workspace .. "/.cargo/config.toml", { "[build]", 'target-dir = "workspace-target"' })
  write(intermediate .. "/.cargo/config.toml", { "[build]", 'target-dir = "intermediate-target"' })
  write(project .. "/.cargo/config.toml", { "[build]", 'target-dir = "member-target"' })
  workspace = assert(vim.uv.fs_realpath(workspace))
  intermediate = workspace .. "/nested"
  vim.api.nvim_set_current_dir(project)
  project = vim.fn.getcwd()

  local selected = analyze(workspace)
  assert(selected.cargo.configPath == project .. "/.cargo/config.toml", "Nearest member config was not selected")
  assert(selected.cargo.buildScripts.invocationStrategy == "once" and selected.check.invocationStrategy == "once")
  assert(selected.check.command == "clippy" and selected.cargo.features == nil, "Default Cargo intent changed")

  write(project .. "/.cargo/config", { "[build]", 'target-dir = "legacy-member-target"' })
  assert(analyze(workspace).cargo.configPath == project .. "/.cargo/config", "Cargo's extensionless config must win")
  assert(
    analyze(project).cargo.configPath == nil,
    "Workspace-root config should retain rust-analyzer's default discovery"
  )
  assert(vim.fn.delete(project .. "/.cargo/config") == 0)
  assert(vim.fn.delete(project .. "/.cargo/config.toml") == 0)
  assert(analyze(workspace).cargo.configPath == intermediate .. "/.cargo/config.toml", "Intermediate config was missed")
  assert(vim.fn.delete(intermediate .. "/.cargo/config.toml") == 0)
  assert(analyze(workspace).cargo.configPath == nil, "Root config should not become a member override")

  local custom = vim.deepcopy(defaults)
  custom["rust-analyzer"].cargo.configPath = fixture_dir .. "/explicit.toml"
  custom["rust-analyzer"].cargo.buildScripts = {
    enable = false,
    overrideCommand = { "custom-build", "argument" },
    invocationStrategy = "per_workspace",
  }

  custom["rust-analyzer"].check.overrideCommand = { "custom-check", "argument" }
  custom["rust-analyzer"].check.invocationStrategy = "per_workspace"
  local original_custom = vim.deepcopy(custom)
  assert(vim.deep_equal(settings(workspace, custom), custom), "Explicit commands or config were overwritten")
  assert(vim.deep_equal(custom, original_custom), "Caller-owned custom settings were mutated")

  local preserved = vim.deepcopy(defaults)
  preserved["rust-analyzer"].cargo.buildScripts = { enable = false, invocationStrategy = "per_workspace" }
  local generated = analyze(workspace, preserved)
  assert(generated.cargo.buildScripts.enable == false, "Existing build-script settings were lost")
  assert(generated.cargo.buildScripts.invocationStrategy == "per_workspace", "Explicit invocation strategy was lost")
  assert(preserved["rust-analyzer"].cargo.buildScripts.overrideCommand == nil, "Generated command mutated its input")
  assert(vim.deep_equal(settings(nil, defaults), defaults), "Missing workspace root should leave settings unchanged")
  vim.api.nvim_set_current_dir(fixture_dir)
  assert(
    vim.deep_equal(settings(workspace, defaults), defaults),
    "CWD outside a Cargo project should leave settings unchanged"
  )

  -- Execute the real generated shell argv against a local Cargo sink, without compilation or downloads.
  local tools = fixture_dir .. "/tools"
  write(tools .. "/cargo", { "#!/bin/sh", 'printf \'%s\\n\' "$PWD" "$@"' })
  assert(vim.fn.setfperm(tools .. "/cargo", "rwx------") == 1)

  for command, argv in pairs {
    check = selected.cargo.buildScripts.overrideCommand,
    clippy = selected.check.overrideCommand,
  } do
    local result =
      vim.system(argv, { cwd = fixture_dir, env = { PATH = tools .. ":" .. vim.env.PATH }, text = true }):wait()
    assert(result.code == 0, command .. " shell command failed: " .. result.stderr)
    local received = vim.split(result.stdout, "\n", { trimempty = true })
    local expected = { project, command, "--message-format=json", "--keep-going" }
    assert(vim.deep_equal(received, expected), command .. " changed Cargo's working directory or raw arguments")
  end

  vim.api.nvim_set_current_dir(original_cwd)
  assert(vim.fn.delete(fixture_dir, "rf") == 0, "Could not remove temporary fixtures")
  print "PASS: Rust settings discovery, config precedence, option preservation, once invocation, and real shell argv/cwd"
end

vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)

  if not ok then
    pcall(vim.api.nvim_set_current_dir, original_cwd)
    io.stderr:write(err .. "\n")

    if fixture_dir then
      io.stderr:write("Temporary fixtures retained: " .. fixture_dir .. "\n")
    end

    vim.cmd "cquit 1"
    return
  end

  vim.cmd "qa!"
end, 100)
