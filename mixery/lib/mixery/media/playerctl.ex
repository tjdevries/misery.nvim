defmodule Mixery.Media.Playerctl do
  def get_song() do
    {song, 0} =
      System.cmd("playerctl", [
        "metadata",
        "--player",
        "firefox",
        "--format",
        "{{ artist }}: {{ title }}"
      ])

    song
  end

  def pause() do
    System.cmd("playerctl", ["pause", "--player", "firefox"])
  end

  def play() do
    System.cmd("playerctl", ["play", "--player", "firefox"])
  end

  def status() do
    case dbg(System.cmd("playerctl", ["status", "--player", "firefox"])) do
      {"Playing\n", 0} -> :playing
      {"Paused\n", 0} -> :paused
      {"Stopped\n", 0} -> :stopped
      _ -> :unknown
    end
  end
end
