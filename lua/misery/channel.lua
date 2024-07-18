local Websocket = require("websocket").Websocket

local scheduler = require "misery.scheduler"

---@class mixery.Effect
---@field id string
---@field title string
---@field prompt string

---@class mixery.User
---@field id string
---@field login string
---@field display string

---@class mixery.ExecuteEffect
---@field id string
---@field user mixery.User
---@field effect mixery.Effect
---@field input string|nil

local M = {}

local socket

local response_handlers = {}

local message_count = 0
local pid = vim.fn.getpid()

local send_message = function(topic_name, event_name, payload)
  message_count = message_count + 1
  payload = payload or vim.empty_dict()

  local message_id = string.format("neovim:%s:%s", pid, message_count)

  -- [join_reference, message_reference, topic_name, event_name, payload]
  socket:send_text(vim.json.encode {
    string.format("neovim:%s", pid),
    message_id,
    topic_name,
    event_name,
    payload,
  })

  return message_id
end

local send_heartbeat = function()
  -- [null, "2", "phoenix", "heartbeat", {}]
  local message_id = send_message("phoenix", "heartbeat")

  response_handlers[message_id] = function(payload)
    if payload.status ~= "ok" then
      vim.notify(string.format("[misery] Failed to get heartbeat back\n%s", vim.inspect(payload)))
    end
  end
end

local heartbeat_timer = vim.uv.new_timer()
M.start = function()
  scheduler.start()

  ---@diagnostic disable-next-line: missing-fields
  socket = Websocket:new {
    host = "127.0.0.1",
    port = 4000,
    path = "/nvim/websocket?vsn=2.0.0",
  }

  socket:add_on_connect(vim.schedule_wrap(function()
    print "[mixery] connected to mixery.nvim"

    local message_reference = send_message("neovim:lobby", "phx_join", {
      colorschemes = vim.fn.getcompletion("", "color"),
    })

    --- Handle the join response, which may contain tasks to execute
    response_handlers[message_reference] = function(payload)
      local queued = payload.response.queued
      for _, execution in ipairs(queued) do
        ---@type mixery.ExecuteEffect
        execution = execution

        local name = string.format("misery.tasks.%s", execution.effect.id)
        local ok, task = pcall(require, name)
        if ok then
          task(execution, scheduler.add_task)
        else
          print(string.format("No task found for %s", name or ""))
        end
      end
    end

    -- Start heartbeat so we don't drop the connection, if no messages in 10 seconds
    heartbeat_timer:stop()
    heartbeat_timer:start(1 * 1000, 10 * 1000, function()
      send_heartbeat()
    end)
  end))

  socket:add_on_message(vim.schedule_wrap(function(frame)
    local payload = vim.json.decode(frame.payload)

    ---@type string
    local message_reference = payload[2]

    ---@type string
    local name = payload[4]

    ---@type mixery.ExecuteEffect
    local args = payload[5]

    if name == "phx_reply" then
      local handler = response_handlers[message_reference]
      if handler then
        response_handlers[message_reference] = nil
        handler(args)
        return
      end

      print("unhandled phx_reply:", vim.inspect(payload))
      return
    end

    if name == "phx_error" then
      print(string.format("phx_error: %s", vim.inspect(payload[5])))
      return
    end

    -- print(vim.inspect { name = name, args = args })

    name = string.format("misery.tasks.%s", name)
    local ok, task = pcall(require, name)
    if ok then
      task(args, scheduler.add_task)
    else
      print(string.format("No task found for %s", name or ""))
    end
  end))

  socket:add_on_close(vim.schedule_wrap(function()
    print "==== OH NO, WE HAVE CLOSED THE CONNECTION ===="

    vim.defer_fn(function()
      socket = Websocket:new {
        host = "127.0.0.1",
        port = 4000,
        path = "/nvim/websocket?vsn=2.0.0",
      }
      socket:connect()
    end, 100)
  end))

  socket:connect()
end

M.send_effect_completed = function(execution_id)
  send_message("neovim:lobby", "effect_execution_completed", { execution_id = execution_id })
end

M.send_key = function(key)
  send_message("neovim:lobby", "neovim_on_key", { key = key })
end

return M
