if SCHEDULER_TIMER then
  SCHEDULER_TIMER:close()
  SCHEDULER_TIMER = nil
end

SCHEDULER_TIMER = vim.uv.new_timer()

local M = {}

M.tasks = {}

local stopped = false

M.add_task = function(task)
  stopped = false
  table.insert(M.tasks, task)
end

M.start = vim.schedule_wrap(function()
  if stopped then
    return
  end

  if #M.tasks == 0 then
    if not SCHEDULER_TIMER then
      SCHEDULER_TIMER = vim.uv.new_timer()
    end

    SCHEDULER_TIMER:start(1000, 0, M.start)
    return
  end

  local first = M.tasks[1]
  for i = 1, #M.tasks - 1 do
    M.tasks[i] = M.tasks[i + 1]
  end

  -- Remove the last one LUL
  M.tasks[#M.tasks] = nil

  -- Just start our next one
  M._current_task = first
  first:_add_on_complete(M.start)
  first:start()
end)

M.stop = function()
  if SCHEDULER_TIMER then
    SCHEDULER_TIMER:close()
    SCHEDULER_TIMER = nil
  end

  if M._current_task then
    M._current_task:stop()
  end

  stopped = true
  M.tasks = {}
end

return M
