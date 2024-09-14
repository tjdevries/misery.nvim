defmodule Mixery.Event.Notification do
  use TypedStruct

  typedstruct module: Video, enforce: true do
    field :url, String.t()
    field :style, String.t()
  end

  typedstruct module: Themesong, enforce: true do
    field :url, String.t()
    field :message, String.t()
  end

  typedstruct module: SelfSubscriber, enforce: true do
    field :url, String.t()
    field :sub_tier, Mixery.Twitch.SubTier.t()
    field :cumulative, pos_integer()
    field :duration, pos_integer()
    field :streak, pos_integer()
    field :message, String.t() | nil
  end

  typedstruct module: GiftSubscription, enforce: true do
    field :url, String.t()
    field :total, pos_integer()
    field :sub_tier, Mixery.Twitch.SubTier.t()
    field :message, String.t() | nil
  end

  typedstruct module: Text, enforce: true do
    field :message, String.t()
    field :length_ms, integer()
  end

  typedstruct enforce: true do
    field :id, String.t()
    field :user, Mixery.Twitch.User.t() | nil
    field :kind, :video | :themesong | :self_subscriber | :gift_subscription | :text
    field :data, Video.t() | Themesong.t() | SelfSubscriber.t() | GiftSubscription.t() | Text.t()
  end

  @spec video(String.t(), String.t(), Mixery.Twitch.User.t() | nil) :: __MODULE__.t()
  def video(url, style, user \\ nil) do
    %__MODULE__{
      id: UUID.uuid4(),
      user: user,
      kind: :video,
      data: %Video{url: url, style: style}
    }
  end

  @spec themesong(String.t(), String.t(), Mixery.Twitch.User.t()) :: __MODULE__.t()
  def themesong(url, message, user) do
    %__MODULE__{
      id: UUID.uuid4(),
      user: user,
      kind: :themesong,
      data: %Themesong{url: url, message: message}
    }
  end

  @spec text(String.t(), integer(), Mixery.Twitch.User.t() | nil) :: __MODULE__.t()
  def text(message, length_ms \\ 2000, user \\ nil) do
    %__MODULE__{
      id: UUID.uuid4(),
      user: user,
      kind: :text,
      data: %Text{message: message, length_ms: length_ms}
    }
  end

  @spec self_subscriber([
          {:user, Mixery.Twitch.User.t()}
          | {:sub_tier, Mixery.Twitch.SubTier.t()}
          | {:url, String.t()}
          | {:cumulative, pos_integer()}
          | {:duration, pos_integer()}
          | {:streak, pos_integer()}
          | {:message, String.t()}
        ]) :: __MODULE__.t()
  def self_subscriber(opts) do
    user = Keyword.fetch!(opts, :user)
    sub_tier = Keyword.fetch!(opts, :sub_tier)
    url = Keyword.fetch!(opts, :url)
    cumulative = Keyword.fetch!(opts, :cumulative)
    duration = Keyword.fetch!(opts, :duration)
    streak = Keyword.fetch!(opts, :streak)
    message = Keyword.fetch!(opts, :message)

    %__MODULE__{
      id: UUID.uuid4(),
      user: user,
      kind: :self_subscriber,
      data: %SelfSubscriber{
        url: url,
        sub_tier: sub_tier,
        cumulative: cumulative,
        duration: duration,
        streak: streak,
        message: message
      }
    }
  end

  @spec gift_subscription([
          {:user, Mixery.Twitch.User.t()}
          | {:url, String.t()}
          | {:total, pos_integer()}
          | {:sub_tier, Mixery.Twitch.SubTier.t()}
          | {:message, String.t()}
        ]) :: __MODULE__.t()
  def gift_subscription(opts) do
    user = Keyword.fetch!(opts, :user)
    url = Keyword.fetch!(opts, :url)
    total = Keyword.fetch!(opts, :total)
    sub_tier = Keyword.fetch!(opts, :sub_tier)
    message = Keyword.fetch!(opts, :message)

    %__MODULE__{
      id: UUID.uuid4(),
      user: user,
      kind: :gift_subscription,
      data: %GiftSubscription{
        url: url,
        total: total,
        sub_tier: sub_tier,
        message: message
      }
    }
  end

  typedstruct module: Ended, enforce: true do
    field :event, __MODULE__.t()
  end
end
