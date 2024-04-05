local Task = require("misery.task").Task

--- Pencil mode
---@param opts? {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (120 * 1000)

  callback(Task.new {
    args = opts,
    name = "Tablet Keyboard",
    timeout = timeout,
    start = function()
      vim.keymap.set({ "i", "c" }, "escape", "<ESC>")
      vim.keymap.set({ "i", "c" }, "enter", "<CR>")
    end,
    update = function(self)
      return {}
    end,
    done = function()
      vim.keymap.del("i", "escape")
      vim.keymap.del("c", "escape")
      vim.keymap.del("i", "enter")
      vim.keymap.del("c", "enter")
    end,
  })
end

return create
