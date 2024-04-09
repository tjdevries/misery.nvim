defmodule Mixery.Twitch.UserBadges do
  defstruct [:sub_tier, :moderator, :vip, :broadcaster]
end

defmodule Mixery.Twitch.Message do
  defstruct [:user, :text, :badges]
end

defmodule Mixery.Twitch.ChatHandler do
  require Logger

  alias Mixery.Coin
  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Twitch
  alias Mixery.Twitch.Message
  alias Mixery.ChatMessage

  # it's more common to grab all the variables from matching in the first line of the function like
  # %{"chatter_user_login" => user_login, "chatter_user_id" => user_id, "message" => %{"text" => text}} = event
  def handle_message(event) do
    user_id = event["chatter_user_id"]
    user_login = event["chatter_user_login"]
    user_display = event["chatter_user_name"]
    user = Twitch.upsert_user(user_id, %{login: user_login, display: user_display})

    text = event["message"]["text"]
    message = %Message{user: user, text: text, badges: parse_badges(event["badges"])}

    # query =
    #   from c in ChatMessage,
    #     where: c.twitch_user_id == ^user.id and fragment("date(?) >= CURRENT_DATE", c.updated_at)
    #
    # dbg(Repo.aggregate(query, :count))

    %ChatMessage{twitch_user_id: user.id, text: text}
    |> Repo.insert!()

    dbg({:chat_message, "Processing: #{user.display}: #{text}"})

    Mixery.broadcast_event(%Event.Chat{user: user, message: text})

    case text do
      "!" <> _ -> handle_command(message)
      _ -> nil
    end
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
end
