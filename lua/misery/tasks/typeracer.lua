local Task = require("misery.task").Task

local group = vim.api.nvim_create_augroup("typeracer", {})

--- Pencil mode
---@param opts? {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  -- local timeout = opts.timeout or (1000 * 60 * 5)
  local timeout = 1000 * 10
  local minimum_time = 4200

  local last_changed = 0
  callback(Task.new {
    args = opts,
    name = "Pencil Mode",
    timeout = timeout,
    start = function()
      last_changed = vim.uv.now()

      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "CmdlineChanged" }, {
        group = group,
        callback = function()
          last_changed = vim.uv.now()
        end,
      })
    end,
    update = function(self)
      if not self.bufnr then
        return
      end

      if vim.bo.filetype == "help" then
        last_changed = vim.uv.now()
      end

      local remaining = math.floor(self.remaining / 1000)
      if vim.uv.now() - last_changed < minimum_time then
        local fail_remaining = (minimum_time - (vim.uv.now() - last_changed)) / 1000
        return { string.format("Time until fail: %0.1f", fail_remaining) }
      end

      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local random_line = math.random(#lines)
      print("[MISERY] deleted line:", random_line)
      vim.api.nvim_buf_set_lines(0, random_line - 1, random_line, false, {})

      return {}
    end,
    done = function()
      group = vim.api.nvim_create_augroup("typeracer", { clear = true })
    end,
  })
end

return create
