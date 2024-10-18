local Task = require("misery.task").Task

local ns = vim.api.nvim_create_namespace "Fog of War"

local make_floaty = function(blend, width, row)
  local buffer = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buffer, false, {
    relative = "cursor",
    style = "minimal",
    width = width * 2,
    height = 1,
    row = row,
    col = -width,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    once = true,
    callback = function()
      pcall(vim.api.nvim_buf_delete, buffer, { force = true })
      pcall(vim.api.nvim_win_close, win, true)
    end,
  })

  vim.wo[win].winblend = blend
  vim.wo[win].winhl = "Normal:Misery"
end

local flashlight_row = function(i, opts)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local start = math.max(0, cursor[2] - opts.width)
  vim.api.nvim_buf_add_highlight(0, ns, "Misery", i, 0, start)

  local finish = math.min(#vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1], cursor[2] + opts.width)
  vim.api.nvim_buf_add_highlight(0, ns, "Misery", i, finish, -1)

  if opts.row == 0 then
    return
  end

  make_floaty(opts.blend, opts.width, opts.row)
  make_floaty(opts.blend, opts.width, -opts.row)
end

--- Pencil mode
---@param opts {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (20 * 1000)

  callback(Task.new {
    args = opts,
    name = "Fog of War",
    timeout = timeout,
    start = function()
      vim.cmd [[hi Misery guibg=#111111 guifg=#111111]]

      vim.opt.cursorline = false
      vim.opt.list = false

      local group = vim.api.nvim_create_augroup("Fog of War", {})
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        callback = function()
          vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

          local cursor = vim.api.nvim_win_get_cursor(0)
          for i = 0, vim.api.nvim_buf_line_count(0) - 1 do
            if i == cursor[1] - 1 then
              flashlight_row(i, { width = 8, row = 0 })
            elseif i == cursor[1] - 2 or i == cursor[1] then
              flashlight_row(i, { width = 7, row = 1, blend = 50 })
            elseif i == cursor[1] - 3 or i == cursor[1] + 1 then
              flashlight_row(i, { width = 4, row = 2, blend = 20 })
            else
              vim.api.nvim_buf_add_highlight(0, ns, "Misery", i, 0, -1)
            end
          end
        end,
      })
    end,
    update = function(self)
      if not self.bufnr then
        return
      end

      return {}
    end,
    done = function()
      vim.opt.list = true
      vim.opt.cursorline = true

      vim.api.nvim_create_augroup("Fog of War", { clear = true })
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      end
    end,
  })
end

return create
