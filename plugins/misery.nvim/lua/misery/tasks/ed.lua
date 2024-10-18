return require("misery.task").make_task {
  name = "Ed",
  timeout = 5 * 60 * 1000,
  requires_focus = false,
  start = function(self)
    vim.cmd.w()
    self.state.job = vim.system { "kitty", "ed", vim.fn.expand "%:p" }
  end,
  done = function(self)
    self.state.job:kill()
  end,
}
