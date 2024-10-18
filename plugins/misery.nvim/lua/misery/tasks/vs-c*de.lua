return require("misery.task").make_task {
  name = "VS C*de",
  timeout = 15 * 60 * 1000,
  requires_focus = false,
  start = function()
    vim.cmd.w()
    vim.system { "code", vim.fn.expand "%:p" }
  end,
  done = function()
    vim.system { "pkill", "code" }
  end,
}
