local data_dir = vim.fn.stdpath "data"
local config_dir = vim.fn.stdpath "config"
local modern = vim.fn.has "nvim-0.12" == 1

local M = {
  modern = modern,
  plugin_root = data_dir .. (modern and "/lazy-0.12" or "/lazy"),
  parser_root = data_dir .. (modern and "/site-0.12" or "/site"),
  lockfile = config_dir .. (modern and "/lazy-lock.json" or "/lazy-lock-0.11.json"),
}

function M.prepare_runtime()
  if not modern then
    return
  end

  -- Keep the 0.11 parser/query directory out of the 0.12 runtime.
  vim.opt.rtp:remove(data_dir .. "/site")
  vim.opt.rtp:remove(data_dir .. "/site/after")
  vim.opt.rtp:prepend(M.parser_root)
end

return M
