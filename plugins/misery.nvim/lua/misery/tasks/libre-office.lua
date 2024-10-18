return require("misery.task").make_task {
  name = "Libre Office",
  timeout = 5 * 60 * 1000,
  requires_focus = false,
  start = function()
    vim.cmd.w()
    vim.system { "libreoffice", "--writer", vim.fn.expand "%:p" }
  end,
  done = function()
    vim.system { "pkill", "soffice.bin" }
  end,
}
