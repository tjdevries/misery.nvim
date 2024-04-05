defmodule Mix.Tasks.TestSounds do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    mp3_url =
      "https://raw.githubusercontent.com/membraneframework/membrane_demo/master/simple_pipeline/sample.mp3"

    Membrane.Pipeline.start_link(Mixery.Media.AudioPlayerPipeline, mp3_url)
  end
end
