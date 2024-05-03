return require("misery.task").make_task {
  name = "Emacs",
  timeout = 5 * 60 * 1000,
  requires_focus = false,
  start = function()
    vim.cmd.w()
    vim.system { "emacs", vim.fn.expand "%:p" }
  end,
  done = function()
    vim.system { "pkill", "emacs" }
  end,
}
