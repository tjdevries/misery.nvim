local ns = vim.api.nvim_create_namespace "misery-on-key"

local ignored_filetypes = {
  terminal = true,
}

local enabled_modes = {
  n = true,
}

-- vim.on_key(nil, ns)
vim.api.nvim_create_user_command("StartMisery", function()
  require("misery.channel").start()

  vim.on_key(function(_, typed)
    if not typed or typed == "" then
      return
    end

    if ignored_filetypes[vim.bo.filetype] then
      return
    end

    local mode = vim.api.nvim_get_mode().mode
    if not enabled_modes[mode] then
      return
    end

    require("misery.channel").send_key(vim.fn.keytrans(typed))
  end, ns)
end, {})
