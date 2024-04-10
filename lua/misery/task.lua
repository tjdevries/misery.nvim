---@type {lost?: number, gained?: number}[]
local focused = {}

local focus_group = vim.api.nvim_create_augroup("misery-focus-group", { clear = true })
vim.api.nvim_create_autocmd("FocusLost", {
  group = focus_group,
  callback = function()
    table.insert(focused, { lost = vim.uv.now() })
  end,
})
vim.api.nvim_create_autocmd("FocusGained", {
  group = focus_group,
  callback = function()
    if #focused == 0 then
      table.insert(focused, { lost = vim.uv.now() })
    end

    focused[#focused].gained = vim.uv.now()
  end,
})

---@type misery.Task[]
local tasks = {}

---@class misery.Task
---@field state table
---@field opts misery.TaskOpts
---@field bufnr number
---@field timer uv_timer_t
---@field start_time number: Start time (vim.uv.now())
local Task = {}
Task.__index = Task

---@class misery.TaskOpts
---@field name string
---@field args mixery.RewardRedemption
---@field timeout number: Total number of ms to run
---@field requires_focus? boolean: Whether the task requires the window to be focused
---@field update_width? number: Width of the update window
---@field start fun(misery.Task): nil
---@field update fun(misery.Task): nil
---@field done fun(misery.Task, boolean): nil

--- Creates a new Task.
---@param opts misery.TaskOpts
function Task.new(opts)
  local obj = setmetatable({
    opts = opts,
    state = {},
    _after = {},
  }, Task)

  table.insert(tasks, obj)

  return obj
end

function Task:_add_on_complete(cb)
  table.insert(self._after, cb)
end

function Task:stop()
  self._after = {}
  self:done(false)
end

function Task:start()
  local timeout
  if type(self.opts.timeout) == "function" then
    timeout = self.opts.timeout()
  else
    timeout = self.opts.timeout
  end

  local requires_focus = true
  if self.opts.requires_focus ~= nil then
    requires_focus = self.opts.requires_focus
  end

  local col = vim.o.columns
  local width = self.opts.update_width or 30

  -- Clean up focused variable
  focused = {}

  self.start_time = vim.loop.now()

  local make_window = function()
    if self.win then
      pcall(vim.api.nvim_win_close, self.win, true)
      self.win = nil
    end

    self.win = vim.api.nvim_open_win(self.bufnr, false, {
      relative = "editor",
      row = 1,
      col = col - width,
      height = 3,
      width = width,
      style = "minimal",
      border = "single",
    })

    vim.wo[self.win].wrap = false
  end

  self.bufnr = vim.api.nvim_create_buf(false, true)
  make_window()

  self.opts.start(self)

  self.timer = vim.loop.new_timer()
  self.timer:start(
    100,
    100,
    vim.schedule_wrap(function()
      local windows = vim.api.nvim_tabpage_list_wins(0)
      if not vim.tbl_contains(windows, self.win) then
        -- Make a new window
        make_window()
      end

      -- Not all events require focus (for example, opening VS C*de)...
      --    So we have to skip these checks for some tasks.
      local focus_elapsed = 0
      local is_focused = true
      if requires_focus then
        for _, focus_pair in ipairs(focused) do
          if not focus_pair.gained then
            is_focused = false
            break
          end

          focus_elapsed = focus_elapsed + (focus_pair.gained - focus_pair.lost)
        end
      end

      if is_focused then
        self.remaining = focus_elapsed + timeout - (vim.loop.now() - self.start_time)
      else
        self.remaining = self.remaining or timeout
      end

      if self.remaining <= 0 then
        self:done(true)
        return
      end

      local ok, message = pcall(self.opts.update, self)
      if not ok then
        vim.notify(string.format("[MISERY]: task:update() failed\n%s", message))
      end

      if not ok then
        return self:done(false)
      end

      if message == true then
        return self:done(true)
      elseif type(message) == "table" then
        -- Add a title
        table.insert(message, 1, string.format("%s (%s)", self.opts.name, self.opts.args.user.login or "<unknown>"))

        -- Add time remaining
        local remaining = math.floor(self.remaining / 1000)
        table.insert(message, string.format("Time Remaining: %d", remaining))

        -- Display message
        vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, message)
      end
    end)
  )
end

function Task:done(success)
  -- Clean up focused variable
  focused = {}

  self.timer:close()
  self.timer = nil

  local ok, msg = pcall(self.opts.done, self, success)
  if not ok then
    vim.notify(string.format("[MISERY]: task:done() failed\n%s", msg))
  end

  pcall(vim.api.nvim_buf_delete, self.bufnr, { force = true })
  pcall(vim.api.nvim_win_close, self.win, true)

  self.bufnr = nil
  self.win = nil

  for _, cb in ipairs(self._after) do
    local after_ok, after_msg = pcall(cb)
    if not after_ok then
      vim.notify(string.format("[MISERY]: task:_after() failed\n%s", after_msg))
    end
  end
end

return {
  Task = Task,
  tasks = tasks,
  make_task = function(init)
    return function(opts, cb)
      opts = vim.tbl_deep_extend("force", init, opts or {})

      cb(Task.new {
        name = opts.name,
        timeout = opts.timeout,
        requires_focus = opts.requires_focus,
        args = opts,
        start = init.start,
        update = function()
          return {}
        end,
        done = init.done,
      })
    end
  end,
}
