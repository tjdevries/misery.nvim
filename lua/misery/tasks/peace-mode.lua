local Task = require("misery.task").Task

--- Peace mode
---@param opts? {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (5 * 60 * 1000)
  callback(Task.new {
    args = opts,
    name = "Peace Mode",
    timeout = timeout,
    start = function() end,
    update = function()
      return { "<3" }
    end,
    done = function() end,
  })
end

return create
