local Task = require("misery.task").Task

--- Pencil mode
---@param opts {timeout: number, user_login: string}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (15 * 1000)

  callback(Task.new {
    args = opts,
    name = "Random Colorscheme",
    timeout = timeout,
    start = function(self)
      local colorschemes = vim.api.nvim_get_runtime_file("colors/*", true)
      colorschemes = vim.tbl_map(function(colorscheme)
        return vim.fn.fnamemodify(colorscheme, ":t:r")
      end, colorschemes)

      local random_colorscheme = colorschemes[math.random(#colorschemes)]
      vim.cmd.hi "clear"
      vim.cmd.colorscheme(random_colorscheme)

      self.state.colorscheme = random_colorscheme
    end,
    update = function(self)
      return { string.format("Colorscheme: %s", self.state.colorscheme) }
    end,
    done = function()
      vim.cmd.hi "clear"
      vim.cmd.colorscheme "gruvbuddy"
    end,
  })
end

return create
