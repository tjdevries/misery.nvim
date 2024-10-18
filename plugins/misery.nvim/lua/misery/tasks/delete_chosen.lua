local Task = require("misery.task").Task

--- Delete a random file
---@param opts? table
local create = function(opts, callback)
  opts = opts or {}

  local dir = vim.fs.dir(vim.fn.stdpath "config", { depth = 99 })
  local files = vim
    .iter(dir)
    :filter(function(_, type)
      return type == "file"
    end)
    :map(function(item)
      return item
    end)
    :totable()

  vim.ui.select(files, {}, function(choice)
    if not choice then
      return
    end

    callback(Task.new {
      args = opts,
      name = "delete_random",
      timeout = 3000,
      update_width = 40,
      start = function(self)
        self.state.path = choice
      end,
      update = function(self)
        local relative = string.gsub(self.state.path, vim.fn.stdpath "config" .. "/", "")
        return { string.format("Deleting: %s", relative) }
      end,
      done = function(self, success)
        if not success then
          vim.notify(string.format("not gonna delete: %s", self.state.path))
          return
        end

        vim.notify(string.format("DELETING: %s", self.state.path))
        -- vim.fn.delete(self.state.path)
      end,
    })
  end)
end

return create
