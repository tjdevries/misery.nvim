local Task = require("misery.task").Task

local set_user_var = function(text)
  local stdout = vim.loop.new_tty(1, false)

  -- printf "\033]1337;SetUserVar=%s=%s\007" foo `echo -n bar | base64`
  local text = string.format("\x1b]1337;SetUserVar=%s=%s\x07", "FONT_CHANGER", vim.base64.encode(text))
  stdout:write(text)
end

--- Pencil mode
---@param opts? {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (15 * 1000)

  callback(Task.new {
    args = opts,
    name = "Random Font",
    timeout = timeout,
    start = function()
      set_user_var "random"
    end,
    update = function(self)
      return {}
    end,
    done = function()
      set_user_var "default"
    end,
  })
end

return create
