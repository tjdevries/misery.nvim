return require("misery.task").make_task {
  name = "uǝǝɹɔs uʍop ǝpᴉsd∩",
  timeout = 30 * 1000,
  start = function()
    vim.fn.systemlist { "xrandr", "--output", "HDMI-A-0", "--rotate", "inverted" }
  end,
  done = function()
    vim.fn.systemlist { "xrandr", "--output", "HDMI-A-0", "--rotate", "normal" }
  end,
}
