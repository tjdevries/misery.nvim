vim.api.nvim_create_user_command("StartMisery", function()
  require("misery.channel").start()
end, {})
