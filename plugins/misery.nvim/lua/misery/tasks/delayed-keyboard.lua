local curl = require "plenary.curl"
local Task = require("misery.task").Task

--- Delayed Keyboard
---@param opts? {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (60 * 5 * 1000)

  callback(Task.new {
    args = opts,
    name = "Delayed Keyboard",
    timeout = timeout,
    start = function()
      -- Python thing needs to be running...
      curl.put { url = "localhost:8000/grab" }
    end,
    update = function(self)
      return {}
    end,
    done = function()
      curl.put { url = "localhost:8000/ungrab" }
    end,
  })
end

return create
