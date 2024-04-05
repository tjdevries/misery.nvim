local ns = vim.api.nvim_create_namespace "misery-snake"
local group = vim.api.nvim_create_augroup("misery-snake", {})

local Task = require("misery.task").Task

--- Snake mode
---@param opts {timeout: number}
local create = function(opts, callback)
  opts = opts or {}

  local timeout = opts.timeout or (30 * 1000)

  callback(Task.new {
    args = opts,
    name = "Snake",
    timeout = timeout,
    start = function()
      local locations = vim.ringbuf(20)
      vim.api.nvim_create_augroup("misery-snake", {})

      vim.cmd [[hi Misery guibg=#111111 guifg=#111111]]

      vim.opt.cursorline = false
      vim.opt.list = false

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        callback = function()
          vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

          locations:push(vim.api.nvim_win_get_cursor(0))
          local copied = vim.deepcopy(locations)

          local openings = {}
          for location in copied do
            local row, col = unpack(location)
            row = row - 1

            if not openings[row] then
              openings[row] = {}
            end

            table.insert(openings[row], col)
          end

          for _, cols in pairs(openings) do
            table.sort(cols)
          end

          -- print(vim.inspect(openings))
          local width = 2
          for row, cols in pairs(openings) do
            for i, col in ipairs(cols) do
              if i == 1 then
                vim.api.nvim_buf_add_highlight(0, ns, "Misery", row, 0, col - width)
              end

              if i == #cols then
                vim.api.nvim_buf_add_highlight(0, ns, "Misery", row, col + width, -1)
              end

              if i ~= 1 and i ~= #cols then
                if cols[i - 1] ~= col then
                  local start = math.max(cols[i - 1] + width, col - width)
                  local finish = math.min(cols[i - 1] + width, col - width)
                  vim.api.nvim_buf_add_highlight(0, ns, "Misery", row, start, finish)
                end
              end
            end
          end

          for i = 0, vim.api.nvim_buf_line_count(0) - 1 do
            if not openings[i] then
              vim.api.nvim_buf_add_highlight(0, ns, "Misery", i, 0, -1)
            end
          end
        end,
      })
    end,
    update = function(self)
      return {}
    end,
    done = function()
      vim.opt.list = true
      vim.opt.cursorline = true

      vim.api.nvim_create_augroup("misery-snake", { clear = true })
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      end
    end,
  })
end

return create
