local Task = require("misery.task").Task

--- Delete a random file
---@param opts? table
local create = function(opts, callback)
  opts = opts or {}

  callback(Task.new {
    args = opts,
    name = "delete_random",
    timeout = 3000,
    update_width = 40,
    start = function(self)
      local dir = vim.fs.dir(vim.fn.stdpath "config", { depth = 99 })
      local files = vim.tbl_filter(function(file)
        return file[2] == "file" and file[1] ~= "plugin/misery.lua"
      end, vim.iter(dir):totable())

      if vim.tbl_isempty(files) then
        vim.notify "[misery] No files to delete... You wasted your points"
        return
      end

      local random_file = files[math.random(#files)]
      self.state.path = vim.fs.joinpath(vim.fn.stdpath "config", random_file[1])
    end,
    update = function(self)
      if not self.state.path then
        return
      end

      local relative = string.gsub(self.state.path, vim.fn.stdpath "config" .. "/", "")
      return { string.format("Deleting: %s", relative) }
    end,
    done = function(self, success)
      if not self.state.path then
        return
      end

      if not success then
        vim.notify(string.format("not gonna delete: %s", self.state.path))
        return
      end

      vim.notify(string.format("DELETING: %s", self.state.path))
      vim.fn.delete(self.state.path)
    end,
  })
end

return create
