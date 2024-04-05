local M = {}

-- TODO: Set misery to be the same color as Normal, can be done on colorscheme autocmd
vim.cmd [[hi Misery guibg=#111111 guifg=#111111]]

local hide_line_range = function(ns, start, finish)
  if finish == -1 then
    finish = vim.api.nvim_buf_line_count(0) - 1
  end

  local end_col = #vim.api.nvim_buf_get_lines(0, finish, finish + 1, false)[1] - 1

  vim.api.nvim_buf_set_extmark(0, ns, start, 0, { end_line = finish, end_col = end_col, hl_group = "Misery" })
end

M.enable_invisialign = function()
  -- TODO: Disable ai autocomplete
  vim.cmd [[highlight CursorLine guibg=#111111 guifg=#111111]]
end

do
  local ns = vim.api.nvim_create_namespace "visaline"
  local group = vim.api.nvim_create_augroup("visaline", {})

  local make_floaty = function(blend, width, row)
    local buffer = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buffer, false, {
      relative = "cursor",
      style = "minimal",
      width = width * 2,
      height = 1,
      row = row,
      col = -width,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
      once = true,
      callback = function()
        pcall(vim.api.nvim_buf_delete, buffer, { force = true })
        pcall(vim.api.nvim_win_close, win, true)
      end,
    })

    vim.wo[win].winblend = blend
    vim.wo[win].winhl = "Normal:Misery"
  end

  local flashlight_row = function(i, opts)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local start = math.max(0, cursor[2] - opts.width)
    vim.api.nvim_buf_add_highlight(0, ns, "Misery", i, 0, start)

    local finish = math.min(#vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1], cursor[2] + opts.width)
    vim.api.nvim_buf_add_highlight(0, ns, "Misery", i, finish, -1)

    if opts.row == 0 then
      return
    end

    make_floaty(opts.blend, opts.width, opts.row)
    make_floaty(opts.blend, opts.width, -opts.row)
  end

  M.enable_visaline = function()
    vim.opt.cursorline = false
    vim.opt.list = false

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = group,
      callback = function()
        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

        local cursor = vim.api.nvim_win_get_cursor(0)
        for i = 0, vim.api.nvim_buf_line_count(0) - 1 do
          if i == cursor[1] - 1 then
            flashlight_row(i, { width = 8, row = 0 })
          elseif i == cursor[1] - 2 or i == cursor[1] then
            flashlight_row(i, { width = 7, row = 1, blend = 50 })
          elseif i == cursor[1] - 3 or i == cursor[1] + 1 then
            flashlight_row(i, { width = 4, row = 2, blend = 20 })
          else
            vim.api.nvim_buf_add_highlight(0, ns, "Misery", i, 0, -1)
          end
        end
      end,
    })
  end

  M.disable_visaline = function()
    vim.opt.list = true
    vim.opt.cursorline = true

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end
end

do
end

do
  local timer
  M.random_colorscheme = function(timeout)
    if timer then
      timer:close()
      timer = nil
    end

    local colorschemes = vim.api.nvim_get_runtime_file("colors/*", true)
    colorschemes = vim.tbl_map(function(colorscheme)
      return vim.fn.fnamemodify(colorscheme, ":t:r")
    end, colorschemes)

    local random_colorscheme = colorschemes[math.random(#colorschemes)]
    vim.cmd.colorscheme(random_colorscheme)

    print("[MISERY] New colorscheme: " .. random_colorscheme)

    timer = vim.uv.new_timer()
    timer:start(
      timeout or (60 * 1000),
      0,
      vim.schedule_wrap(function()
        vim.cmd.colorscheme "gruvbuddy"
      end)
    )
  end
end

do
  -- This clears the autocommands for this group
  -- local group = vim.api.nvim_create_augroup("misery-ravemode", { clear = true })
  local ns = vim.api.nvim_create_namespace "misery-ravemode"

  -- RAVEMODE_TIMER
  M.enable_ravemode = function()
    if RAVEMODE_TIMER then
      RAVEMODE_TIMER:close()
      RAVEMODE_TIMER = nil
    end

    RAVEMODE_TIMER = vim.uv.new_timer()
    RAVEMODE_TIMER:start(
      0,
      1000,
      vim.schedule_wrap(function()
        hide_line_range(ns, 0, -1)
        vim.defer_fn(function()
          vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
        end, 900)
      end)
    )
  end

  M.disable_ravemode = function()
    RAVEMODE_TIMER:close()
    RAVEMODE_TIMER = nil

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end
end

M.hide_cursor = function()
  vim.cmd [[set guicursor=n-v:hor01-Normal]]
  vim.opt.cursorline = false
  vim.opt.relativenumber = false
  vim.opt.number = false
end

M.show_cursor = function()
  vim.opt.guicursor = { "n-v-c-sm:block", "i-ci-ve:ver25", "r-cr-o:hor20" }
end

return M
