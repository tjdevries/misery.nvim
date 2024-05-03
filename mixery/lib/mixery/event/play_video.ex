defmodule Mixery.Event.PlayVideo do
  defstruct [:video_url, :length_ms]
end

defmodule Mixery.Event.PlayAudio do
  defstruct [:audio_url, :user, :greeting]
end
