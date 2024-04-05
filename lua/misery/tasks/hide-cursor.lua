return require("misery.task").make_task {
  name = "Hidden Cursor",
  timeout = 60 * 1000,
  start = function()
    vim.cmd [[set guicursor=n-v:hor01-Normal]]
    vim.opt.cursorline = false
    vim.opt.relativenumber = false
    vim.opt.number = false
  end,
  done = function()
    vim.opt.guicursor = { "n-v-c-sm:block", "i-ci-ve:ver25", "r-cr-o:hor20" }
  end,
}
