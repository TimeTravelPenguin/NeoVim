-- Run after normal startup with NVIM_TOOLS_MANIFEST pointing to tools.json.
-- NVIM_TOOLS_PLAN=1 prints the selection without loading Mason or downloading.
local handles = {}

local function report(message)
  io.stdout:write("Mason: " .. message .. "\n")
  io.stdout:flush()
end

local function read_selection()
  local manifest_path = vim.env.NVIM_TOOLS_MANIFEST
  assert(manifest_path and manifest_path ~= "", "NVIM_TOOLS_MANIFEST must name the tools manifest")
  local manifest = vim.json.decode(table.concat(vim.fn.readfile(manifest_path), "\n"))
  local mason = manifest.mason or {}
  local aliases = mason.aliases or {}
  local excluded = {}
  local seen = {}
  local selected = {}

  local function resolve(name)
    assert(type(name) == "string" and name ~= "", "Mason package names must be nonempty strings")
    local resolved = aliases[name] or name
    assert(type(resolved) == "string" and resolved ~= "", "Mason aliases must map to nonempty strings")
    return resolved
  end

  for _, name in ipairs(mason.exclude or {}) do
    excluded[resolve(name)] = true
  end

  local configured = vim.deepcopy(require("opts.mason").ensure_installed or {})
  vim.list_extend(configured, mason.extra or {})

  for _, name in ipairs(configured) do
    local resolved = resolve(name)

    if not excluded[resolved] and not seen[resolved] then
      seen[resolved] = true
      selected[#selected + 1] = resolved
    end
  end

  return selected
end

local function all_closed()
  for _, handle in ipairs(handles) do
    if not handle:is_closed() then
      return false
    end
  end

  return true
end

local function cancel_installers()
  for _, handle in ipairs(handles) do
    if not handle:is_closed() then
      report("cancelling " .. handle.package.name)
      pcall(handle.terminate, handle)
    end
  end

  if vim.wait(10000, all_closed, 50) then
    return
  end

  for _, handle in ipairs(handles) do
    if not handle:is_closed() then
      pcall(handle.kill, handle, 9)
    end
  end

  assert(vim.wait(10000, all_closed, 50), "Mason installers did not stop after cancellation")
end

local function install()
  local selected = read_selection()

  if vim.env.NVIM_TOOLS_PLAN == "1" then
    report("selected " .. #selected .. " packages")

    for _, name in ipairs(selected) do
      report(name)
    end

    return
  end

  local timeout_seconds = tonumber(vim.env.NVIM_TOOLS_TIMEOUT or "1800")
  assert(
    timeout_seconds and timeout_seconds > 0 and timeout_seconds < math.huge,
    "NVIM_TOOLS_TIMEOUT must be positive seconds"
  )
  local deadline = vim.uv.hrtime() + timeout_seconds * 1000000000

  local function wait_for(predicate, operation)
    local remaining_ms = math.max(0, math.floor((deadline - vim.uv.hrtime()) / 1000000))
    assert(vim.wait(remaining_ms, predicate, 50), "Timed out while " .. operation)
  end

  -- Lazy runs the user's existing Mason setup, including its install root.
  require("lazy").load { plugins = { "mason.nvim" } }
  local registry = require "mason-registry"
  local registry_done = false
  local registry_success = false
  local registry_result
  report "updating the package registry"

  -- Unlike refresh(), update() also refreshes a still-cached registry.
  registry.update(function(success, result)
    registry_success = success
    registry_result = result
    registry_done = true
  end)

  wait_for(function()
    return registry_done
  end, "updating the Mason registry")

  assert(registry_success, "Mason registry update failed: " .. vim.inspect(registry_result))
  local packages = {}

  -- Resolve every name before starting any installations.
  for _, name in ipairs(selected) do
    packages[#packages + 1] = registry.get_package(name)
  end

  local completed = 0
  local failures = {}

  for _, package in ipairs(packages) do
    report((package:is_installed() and "updating " or "installing ") .. package.name)
    local started, handle = pcall(package.install, package, {}, function(success, result)
      completed = completed + 1

      if success then
        report("finished " .. package.name .. " (" .. completed .. "/" .. #packages .. ")")
      else
        failures[#failures + 1] = package.name .. ": " .. tostring(result)
        report("failed " .. package.name .. " (" .. completed .. "/" .. #packages .. ")")
      end
    end)

    if started then
      handles[#handles + 1] = handle
    else
      completed = completed + 1
      failures[#failures + 1] = package.name .. ": " .. tostring(handle)
      report("could not start " .. package.name)
    end
  end

  wait_for(function()
    return completed == #packages and all_closed()
  end, "installing Mason packages")

  assert(#failures == 0, "Mason installation failures:\n" .. table.concat(failures, "\n"))
  report("all " .. #packages .. " packages finished")
end

vim.schedule(function()
  local ok, err = xpcall(install, debug.traceback)

  if not ok then
    io.stderr:write(tostring(err) .. "\n")
    local cancelled, cancel_error = pcall(cancel_installers)

    if not cancelled then
      io.stderr:write(tostring(cancel_error) .. "\n")
    end

    vim.cmd "cquit 1"
    return
  end

  vim.cmd "qa!"
end)
