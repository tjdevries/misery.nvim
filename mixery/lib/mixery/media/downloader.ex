defmodule Mixery.Media.Downloader do
  alias Mixery.Repo

  @default_args ~w[
      --force-overwrites
      --no-playlist
      --no-continue
      --extract-audio
      --audio-format mp3
      --downloader ffmpeg
  ]

  defmodule Config do
    use TypedStruct

    typedstruct enforce: true do
      @typedoc "Configuration keys for downloading an audio clip"

      field(:twitch_user_id, String.t())
      field(:url, String.t())
      field(:out, String.t())
      field(:from, String.t())
      field(:to, String.t())
      field(:greeting, String.t())
      field(:length_ms, Float.t())
    end
  end

  @spec download(Config.t()) :: nil
  def download(
        %Config{
          twitch_user_id: twitch_user_id,
          url: url,
          out: outfile,
          from: time_from,
          to: time_to,
          length_ms: length_ms,
          greeting: greeting
        } = config
      ) do
    # TODO: Would be fun to make it so people can't share the same URL

    downloader_args = ["--downloader-args", "-ss #{time_from} -to #{time_to}"]

    dbg({:downloading, config})

    case System.cmd("yt-dlp", @default_args ++ downloader_args ++ ["-o", outfile, url],
           stderr_to_stdout: true,
           into: [],
           lines: 1024
         ) do
      {_, 0} ->
        dbg({:done_download, twitch_user_id})

        Repo.insert!(
          %Mixery.Themesong{
            twitch_user_id: twitch_user_id,
            name: greeting,
            path: outfile,
            length_ms: ceil(length_ms)
          },
          on_conflict: :replace_all,
          conflict_target: :twitch_user_id
        )

      result ->
        dbg(result)
    end
  end

  defp split_millis(text) do
    case String.split(text, ".") do
      [timestamp] -> {:ok, timestamp, "0"}
      [timestamp, millis] -> {:ok, timestamp, millis}
      _ -> {:error, "Too many periods in your timestamp: #{text}"}
    end
  end

  defp parse_millis(millis) do
    # "5"   -> 500
    # "01"  -> 010
    # "003" -> 003
    millis =
      String.slice(millis, 0, 4) |> String.pad_trailing(3, "0")

    case Integer.parse(millis) do
      {millis, ""} -> {:ok, millis / 1000}
      _ -> {:error, "Not a valid millisecond value: #{millis}"}
    end
  end

  defp parse_timestamp(timestamp) do
    case String.split(timestamp, ":") do
      [seconds] ->
        case Integer.parse(seconds) do
          {seconds, ""} -> {:ok, seconds}
          _ -> {:error, "Not a valid timestamp: #{timestamp}"}
        end

      [minutes, seconds] ->
        case {Integer.parse(minutes), Integer.parse(seconds)} do
          {{minutes, ""}, {seconds, ""}} -> {:ok, minutes * 60 + seconds}
          _ -> {:error, "Not a valid timestamp: #{timestamp}"}
        end

      [hours, minutes, seconds] ->
        case {Integer.parse(hours), Integer.parse(minutes), Integer.parse(seconds)} do
          {{hours, ""}, {minutes, ""}, {seconds, ""}} ->
            {:ok, hours * 3600 + minutes * 60 + seconds}

          _ ->
            {:error, "Not a valid timestamp: #{timestamp}"}
        end

      _ ->
        {:error, "Not a valid timestamp: #{timestamp}"}
    end
  end

  @spec get_timestamp(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp get_timestamp(text) do
    with {:ok, timestamp, millis} <- split_millis(text),
         {:ok, millis} <- parse_millis(millis),
         {:ok, seconds} <- parse_timestamp(timestamp) do
      {:ok, text, seconds + millis + 0.0}
    end
  end

  defp validate_time(max_duration, start_seconds, stop_seconds) do
    length = stop_seconds - start_seconds

    if length < max_duration do
      {:ok, length * 1000.0}
    else
      {:error,
       "Too big of a time difference -> stop:#{stop_seconds} - start:#{start_seconds} > max:#{max_duration} "}
    end
  end

  defp validate_url(url) do
    case URI.new(url) do
      {:ok, url}
      when url.host in [
             "www.youtube.com",
             "youtube.com",
             "www.youtu.be",
             "youtu.be",
             "www.twitch.tv",
             "twitch.tv",
             "clips.twitch.tv"
           ] ->
        # Verify host is youtube or yout.be or whatever their short version is
        # {:ok, %URI{
        #   fragment: nil,
        #   host: "elixir-lang.org",
        #   path: "/",
        #   port: 443,
        #   query: nil,
        #   scheme: "https",
        #   userinfo: nil
        # }}
        {:ok, url}

      {:ok, url} ->
        {:error, "Unsupported Host: #{url.host}"}

      _ ->
        {:error, "Bad url: #{url}"}
    end
  end

  defp split_themesong_text(text) do
    case String.split(text, " ", trim: true, parts: 5) do
      ["!themesong", url, start, stop] ->
        {:ok, url, start, stop, nil}

      ["!themesong", url, start, stop, greeting] ->
        {:ok, url, start, stop, greeting}

      _ ->
        {:error,
         "!themesong must be in the format of: '!themesong url [HH:]MM:SS[.mmmm] [HH:]MM:SS[.mmm] [optional title]'"}
    end
  end

  @spec from_chat(Mixery.Twitch.Message.t()) :: {:ok, Config.t()} | {:error, String.t()}
  def from_chat(message) do
    text = message.text

    max_duration =
      case {message.badges.sub_tier, message.badges.vip, message.badges.moderator} do
        {:tier_3, _, _} -> 15.1
        {:tier_2, _, _} -> 8.1
        {_, true, _} -> 8.1
        {_, _, true} -> 6.9
        _ -> 5.1
      end

    # !themesong url 00:00.0000 00:00.0000 <optional greeting>
    with {:ok, url, start, stop, greeting} <- split_themesong_text(text),
         {:ok, _} <- validate_url(url),
         {:ok, from, start_seconds} <- get_timestamp(start),
         {:ok, to, stop_seconds} <- get_timestamp(stop),
         {:ok, length_ms} <- validate_time(max_duration, start_seconds, stop_seconds) do
      greeting =
        case greeting do
          nil -> "#{message.user.display} has entered the chat."
          greeting -> greeting
        end

      {:ok,
       %Config{
         twitch_user_id: message.user.id,
         url: url,
         from: from,
         to: to,
         out:
           "/home/tjdevries/plugins/misery.nvim/mixery/priv/static/themesongs/themesong-#{message.user.id}.mp3",
         greeting: greeting,
         length_ms: length_ms
       }}
    end
  end
end
