local Task = require("misery.task").Task

--- Pencil mode
---@param opts {timeout: number, user_login: string, colorscheme: string}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (5 * 1000)

  callback(Task.new {
    args = opts,
    name = "Chosen Colorscheme",
    timeout = timeout,
    start = function(self)
      local colorschemes = vim.api.nvim_get_runtime_file("colors/*", true)
      colorschemes = vim.tbl_map(function(colorscheme)
        return vim.fn.fnamemodify(colorscheme, ":t:r")
      end, colorschemes)

      print(vim.inspect { task = "colorscheme", opts = opts })
      local colorscheme = opts.colorscheme or opts.input
      self.state.colorscheme = colorscheme
      if not vim.tbl_contains(colorschemes, colorscheme) then
        self.state.bad_colorscheme = true
        return
      end

      vim.cmd.hi "clear"
      vim.cmd.colorscheme(colorscheme)
      self.state.colorscheme = colorscheme
    end,
    update = function(self)
      local last_line = nil
      if self.state.bad_colorscheme then
        last_line = string.format("Invalid colorscheme: %s", self.state.colorscheme)
      end

      return { last_line }
    end,
    done = function()
      vim.cmd.hi "clear"
      vim.cmd.colorscheme "gruvbuddy"
    end,
  })
end

return create
