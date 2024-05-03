local Task = require("misery.task").Task

--- Pencil mode
---@param opts? {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = 60 * 5 * 1000

  callback(Task.new {
    args = opts,
    name = "Tablet Keyboard",
    timeout = timeout,
    start = function()
      vim.keymap.set({ "i", "c" }, "escape", "<ESC>")
      vim.keymap.set({ "i", "c" }, "enter", "<CR>")
      vim.keymap.set({ "i", "c" }, "backspace", "<BS>")
    end,
    update = function(self)
      return {}
    end,
    done = function()
      vim.keymap.del("i", "escape")
      vim.keymap.del("c", "escape")
      vim.keymap.del("i", "enter")
      vim.keymap.del("c", "enter")
      vim.keymap.del("i", "backspace")
      vim.keymap.del("c", "backspace")
    end,
  })
end

return create
