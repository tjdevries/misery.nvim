local Task = require("misery.task").Task

local group = vim.api.nvim_create_augroup("no_going_back", {})

--- Pencil mode
---@param opts? {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (1 * 60 * 1000)
  local changed = false
  local last_cursor_position = { 0, 0 }

  local deleted_count = 0

  callback(Task.new {
    args = opts,
    name = "No Going Back",
    timeout = timeout,
    start = function()
      -- Move to the top of the file, so that we can actually code during this segment
      vim.cmd "normal! gg"

      vim.api.nvim_create_autocmd("InsertLeavePre", {
        group = group,
        callback = function()
          if not changed then
            return
          end

          changed = false

          local current_cursor_position = vim.api.nvim_win_get_cursor(0)
          current_cursor_position[1] = current_cursor_position[1] - 1
          last_cursor_position = current_cursor_position
        end,
      })

      -- Reset cursor position when entering new windows
      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function()
          last_cursor_position = { 0, 0 }
        end,
      })

      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function()
          changed = true
        end,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function()
          local current_cursor_position = vim.api.nvim_win_get_cursor(0)
          if last_cursor_position[1] < current_cursor_position[1] then
            last_cursor_position = current_cursor_position
            return
          end

          if last_cursor_position[1] > current_cursor_position[1] then
            if #table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") > 1 then
              deleted_count = deleted_count + 1
            end

            -- clear it all
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
            last_cursor_position = current_cursor_position

            print "=== RIP: THERE'S NO GOING BACK ==="
            return
          end

          if last_cursor_position[2] > current_cursor_position[2] then
            if #table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") > 1 then
              deleted_count = deleted_count + 1
            end

            -- clear it all
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
            last_cursor_position = current_cursor_position

            print "=== RIP: THERE'S NO GOING BACK ==="
            return
          end

          last_cursor_position = current_cursor_position
        end,
      })
    end,
    update = function(self)
      if not self.bufnr then
        return
      end

      return { string.format("Buffers Wiped: %s", deleted_count) }
    end,
    done = function()
      group = vim.api.nvim_create_augroup("no_going_back", { clear = true })
    end,
  })
end

return create
