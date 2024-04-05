-- Other options:
-- https://tuna.voicemod.net/sound/41948bf1-49c8-4ef2-a0bb-a6a4d5a2acb7 (charlie jump scare)
-- https://www.youtube.com/watch?v=f8mL0_4GeV0 (metal pipe falling)
-- https://www.youtube.com/watch?v=-xMfCP2n_UI (air horn)
-- https://www.youtube.com/watch?v=c0Gvwo6yyyA (inception horn)

-- now go normilize audio ls -1 | xargs -I"{}" ffmpeg -i "{}" -filter:a loudnorm norm_"{}"

local root = require("misery").plugin_root

return require("misery.task").make_task {
  name = "JUMPSCARE",
  timeout = function()
    return math.random(5, 10)
  end,
  start = function()
    local dir = vim.fs.dir(vim.fs.joinpath(root, "aux/media/"), { depth = 99 })
    local files = vim.tbl_filter(function(file)
      return file[2] == "file"
    end, vim.iter(dir):totable())

    local file = vim.fs.joinpath(root, "aux/media/", files[math.random(#files)][1])
    print("TRYING TO PLAY:", file)

    vim.system { "mpv", file, "--volume=150" }
  end,
  done = function() end,
}
