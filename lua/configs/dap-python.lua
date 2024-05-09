local function poetry_py_path()
  local handle_poetry = io.popen "poetry env info --path"
  local poetry = handle_poetry:read "*l"

  if handle_poetry:close() and poetry ~= nil and poetry ~= "" then
    return poetry .. "/bin/python"
  end

  local active_path = require("venv-selector").get_active_path()

  -- Check if a venv is currently set
  if active_path ~= nil and active_path ~= "" then
    -- Check if debugpy installed
    local handle_debugpy = io.popen "pip show debugpy"

    if handle_debugpy:close() then
      return active_path .. "/bin/python"
    end
  end

  -- If poetry venv is not set, or debugpy is not installed there,
  -- fallback to debugpy, which is installed by Mason
  return "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
end

return function()
  local dap = require "dap-python"
  dap.setup "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
  -- local py_path = poetry_py_path()
  -- dap.setup(py_path)
  dap.test_runner = "pytest"
end
