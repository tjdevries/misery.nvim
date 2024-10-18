local Task = require("misery.task").Task

local pairs = {
  { "j", "k" },
  { "w", "b" },
  { "h", "l" },
  { "gg", "G" },
  { "e", "ge" },
  { "f", "F" },
  { "t", "T" },
  { "n", "N" },
  { "?", "/" },
  { "#", "*" },
  { "i", "a" },
  { "I", "A" },
  { ";", "," },
  { "$", "^" },
  { "o", "O" },
  { "y", "p" },
  { "u", "<c-r>" },
  { "<c-o>", "<c-i>" },
  { "<c-u>", "<c-d>" },
}

--- Flip the keys
---@param opts? {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (3 * 1000)

  callback(Task.new {
    name = "Flipped Movements",
    timeout = timeout,
    args = opts,
    start = function()
      local make_map = function(lhs, rhs)
        vim.keymap.set("n", lhs, function()
          print(string.format("typed: %s, executed: %s", lhs, rhs))
          return rhs
        end, { expr = true })
      end

      for _, pair in ipairs(pairs) do
        make_map(pair[1], pair[2])
        make_map(pair[2], pair[1])
      end
    end,
    update = function()
      return {}
    end,
    done = function()
      for _, pair in ipairs(pairs) do
        pcall(vim.keymap.del, "n", pair[1])
        pcall(vim.keymap.del, "n", pair[2])
      end
    end,
  })
end

return create
