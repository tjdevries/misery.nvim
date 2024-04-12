defmodule Mixery.Twitch.UserBadges do
  defstruct [:sub_tier, :moderator, :vip, :broadcaster]
end

defmodule Mixery.Twitch.Message do
  defstruct [:user, :text, :badges]
end

defmodule Mixery.Twitch.ChatHandler do
  require Logger

  import Ecto.Query

  alias Mixery.Coin
  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Twitch
  alias Mixery.Twitch.Message
  alias Mixery.Twitch.User
  alias Mixery.ChatMessage

  # it's more common to grab all the variables from matching in the first line of the function like
  # %{"chatter_user_login" => user_login, "chatter_user_id" => user_id, "message" => %{"text" => text}} = event
  def handle_message(event) do
    user_id = event["chatter_user_id"]

    user =
      case Repo.get(User, user_id) do
        nil ->
          user_login = event["chatter_user_login"]
          user_display = event["chatter_user_name"]
          Twitch.upsert_user(%{id: user_id, login: user_login, display: user_display})

        user ->
          user
      end

    text = event["message"]["text"]
    message = %Message{user: user, text: text, badges: parse_badges(event["badges"])}

    query =
      from c in ChatMessage,
        where: c.twitch_user_id == ^user.id and fragment("date(?) >= CURRENT_DATE", c.updated_at)

    is_first_message_today = not Repo.exists?(query)

    %ChatMessage{twitch_user_id: user.id, text: text}
    |> Repo.insert!()

    dbg({:chat_message, "Processing: #{user.display}: #{text}"})

    Mixery.broadcast_event(%Event.Chat{
      user: user,
      message: text,
      is_first_message_today: is_first_message_today
    })

    case text do
      "!" <> _ -> handle_command(message)
      "teejdvFocus" <> _ -> handle_command(message)
      text -> handle_chat_message(message)
      _ -> nil
    end
  end

  defp handle_command(%Message{text: "!leaderboard"}) do
    Mixery.broadcast_event(%Event.SendChat{
      message: "Coin Leaderboard: https://rewards.teej.tv/leaderboard"
    })
  end

  defp handle_command(%Message{text: text})
       when text in ["!elixir", "!whyelixir", "!why-elixir", "!why_elixir"] do
    Mixery.broadcast_event(%Event.SendChat{
      message: "Because i like it :)"
    })
  end

  defp handle_command(%Message{text: "!song"}) do
    {song, 0} =
      System.cmd("playerctl", [
        "metadata",
        "--player",
        "firefox",
        "--format",
        "{{ artist }}: {{ title }}"
      ])

    Mixery.broadcast_event(%Event.SendChat{message: song})
  end

  defp handle_command(%Message{text: "!test", user: %{login: "teej_dv"}}) do
    Mixery.broadcast_event(%Event.Chat{
      user: %{login: "piq9117", id: "103596114"},
      message: "test",
      is_first_message_today: true
    })
  end

  defp handle_command(%Message{text: "!coins"}) do
    Mixery.broadcast_event(%Event.SendChat{
      message: "Rewards Dashboard: https://rewards.teej.tv/dashboard"
    })
  end

  defp handle_command(%Message{text: "!yayayaya"}) do
    Mixery.broadcast_event(%Event.SendChat{
      message: "UNEMPLOYED KEKW"
    })
  end

  defp handle_command(%Message{text: "!focused", badges: badges})
       when badges.broadcaster or badges.moderator do
    Mixery.broadcast_event(%Event.PlayVideo{video_url: "/images/focused.webm", length_ms: 6000})
  end

  defp handle_command(%Message{text: "teejdvFocus" <> _, user: %{display: "wagslane"}}) do
    Mixery.broadcast_event(%Event.PlayVideo{video_url: "/images/focused.webm", length_ms: 6000})
  end

  defp handle_command(%Message{text: "!send " <> msg, badges: badges}) when badges.broadcaster do
    [display, amount] = String.split(msg, " ")

    login =
      String.replace(display, "@", "")
      |> String.downcase()

    user = Repo.get_by!(Twitch.User, login: login)

    {amount, ""} = Integer.parse(amount)

    Mixery.broadcast_event(%Event.SendChat{
      message: "TEEJ SENT: #{user.display} -> #{amount}"
    })

    Coin.insert(user, amount, "teej-custom-sent: probably skill issue")
  end

  defp handle_command(_msg) do
  end

  defp find_tag(badges, tag) do
    Enum.find(badges, fn badge -> badge["set_id"] == tag end)
  end

  defp parse_badges(badges) do
    sub_tier =
      case find_tag(badges, "subscriber") do
        nil ->
          nil

        sub_badge ->
          # turn a string into a number
          case Integer.parse(sub_badge["id"]) do
            {sub_tier, ""} when sub_tier >= 3000 -> :tier_3
            {sub_tier, ""} when sub_tier >= 2000 -> :tier_2
            {_, ""} -> :tier_1
            :error -> nil
          end
      end

    moderator = find_tag(badges, "moderator") != nil
    vip = find_tag(badges, "vip") != nil
    broadcaster = find_tag(badges, "broadcaster") != nil

    %Mixery.Twitch.UserBadges{
      sub_tier: sub_tier,
      moderator: moderator,
      vip: vip,
      broadcaster: broadcaster
    }
  end

  defp handle_chat_message(%Message{text: text}) do
    text = String.downcase(text)

    # TODO: Think about switching between berkeley mono and jetbrains mono everytime
    # someone asks about this just to gaslight them into thinking they can't see the difference
    # between the two all the time.
    if (String.match?(text, ~r/wh(at|ich) font/) or String.contains?(text, "font?")) and
         not String.contains?(text, "pasta"),
       do:
         Mixery.broadcast_event(%Event.SendChat{
           message:
             "Looks like you asked about my font/setup. OS: Pop!_OS, WM: AwesomeWM, Terminal: Wezterm, Font: Berkely Mono"
         })

    if String.contains?(text, "what is your keyboard"),
      do:
        Mixery.broadcast_event(%Event.SendChat{
          message:
            "It's a Dactyl Manuform. I bought it from a nice person on reddit. They were helpful. 5x7 layout with 68g boba U4Ts. These U4Ts use a linear base rather than a tactile one, so the switches have more of a medium tactility. They've been lubed with tribosys 3203 | https://www.youtube.com/shorts/E7lb9sY6aJQ"
        })
  end
end
