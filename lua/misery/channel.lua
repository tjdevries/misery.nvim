pcall(require "misery.scheduler", stop)

_ = R "misery.scheduler"
_ = R "websocket"

local scheduler = require "misery.scheduler"
scheduler.start()

local Websocket = require("websocket").Websocket

---@diagnostic disable-next-line: missing-fields
local socket = Websocket:new {
  host = "127.0.0.1",
  port = 4000,
  path = "/nvim/websocket?vsn=2.0.0",
}

---@class mixery.ChannelReward
---@field reward_id string
---@field key string
---@field title string
---@field prompt string

---@class mixery.RewardRedemption
---@field user_id string
---@field user_login string
---@field user_input string
---@field reward mixery.ChannelReward

socket:add_on_message(vim.schedule_wrap(function(frame)
  local payload = vim.json.decode(frame.payload)

  ---@type string
  local name = payload[4]

  ---@type mixery.RewardRedemption
  local args = payload[5]

  if name == "phx_reply" then
    print "phx_reply"
    return
  end

  if name == "phx_error" then
    print(string.format("phx_error: %s", vim.inspect(payload[5])))
    return
  end

  local name = string.format("misery.tasks.%s", name)
  local ok, task = pcall(require, name)
  if ok then
    task(args, scheduler.add_task)
  else
    print(string.format("No task found for %s", name or ""))
  end
end))

socket:add_on_connect(vim.schedule_wrap(function()
  print "CONNECTED"

  -- [join_reference, message_reference, topic_name, event_name, payload]
  -- ["0", "0", "miami:weather", "phx_join", {"some": "param"}]
  socket:send_text(vim.json.encode {
    "0",
    "0",
    "neovim:lobby",
    "phx_join",
    -- { name = string.format("neovim:%s", vim.fn.getpid()) },
    {},
  })
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
  end, 1000)
end))

socket:connect()
