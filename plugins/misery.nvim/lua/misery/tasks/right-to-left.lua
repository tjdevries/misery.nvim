return require("misery.task").make_task {
  name = "tfel-ot-thgir",
  timeout = 60 * 1000,
  start = function()
    for _, window in ipairs(vim.api.nvim_list_wins()) do
      vim.wo[window].rightleft = true
    end
  end,
  done = function()
    for _, window in ipairs(vim.api.nvim_list_wins()) do
      vim.wo[window].rightleft = false
    end
  end,
}
