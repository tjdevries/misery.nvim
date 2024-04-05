defmodule Mixery.Media.AudioPlayerPipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, mp3_url) do
    # TODO: Would be nice to make sure these can't overlap...
    #   for now maybe we will just leave them?
    #
    #
    # I wonder if I should just play the music w/ aplay in neovim when an event happens though.
    #   That's where we're keeping the queue anyway.
    spec =
      child(%Membrane.Hackney.Source{
        location: mp3_url,
        hackney_opts: [follow_redirect: true]
      })
      |> child(Membrane.MP3.MAD.Decoder)
      |> child(Membrane.PortAudio.Sink)

    {[spec: spec], %{}}
  end
end
