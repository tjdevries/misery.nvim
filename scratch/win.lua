-- window?
local buffer = vim.api.nvim_create_buf(false, true)
local win = vim.api.nvim_open_win(buffer, false, {
  relative = "cursor",
  style = "minimal",
  width = 10,
  height = 1,
  row = -1,
  col = -5,
})

vim.api.nvim_create_autocmd("CursorMoved", {
  once = true,
  callback = function()
    pcall(vim.api.nvim_buf_delete, buffer, { force = true })
    pcall(vim.api.nvim_win_close, win, true)
  end,
})

vim.wo[win].winblend = 50
