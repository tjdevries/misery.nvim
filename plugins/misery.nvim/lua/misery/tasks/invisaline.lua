local Task = require("misery.task").Task

--- Pencil mode
---@param opts {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (15 * 1000)

  callback(Task.new {
    args = opts,
    name = "Invisaline",
    timeout = timeout,
    start = function()
      vim.opt.cursorline = true
      vim.opt.list = false

      vim.cmd [[set guicursor=n-v:ver10-Error]]
      vim.cmd [[highlight CursorLine guibg=#111111 guifg=#111111]]
    end,
    update = function(self)
      if not self.bufnr then
        return
      end

      return {}
    end,
    done = function()
      vim.opt.list = true

      vim.cmd.hi "CursorLine guifg=none guibg=#2b2b2b"
      vim.opt.guicursor = { "n-v-c-sm:block", "i-ci-ve:ver25", "r-cr-o:hor20" }
    end,
  })
end

return create
