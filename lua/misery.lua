local M = {}

M.plugin_root = (function()
  local path = require("plenary.debug_utils").sourced_filepath()
  local root = vim.fn.fnamemodify(path, ":p:h:h")
  return root
end)()

print(M.plugin_root)

return M
