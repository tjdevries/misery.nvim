defmodule Mixery.Event.Subscription do
  use TypedStruct

  alias Mixery.Twitch
  alias Mixery.Twitch.SubTier

  defmodule Sub do
    typedstruct enforce: true do
      field :sub_tier, SubTier.t()
      field :duration, pos_integer()
    end

    @spec from_event(map) :: __MODULE__.t()
    def from_event(event) do
      sub = event["sub"]

      %__MODULE__{
        sub_tier: SubTier.from_string(sub["sub_tier"]),
        duration: sub["duration_months"]
      }
    end
  end

  defmodule ReSub do
    typedstruct enforce: true do
      field :sub_tier, SubTier.t()
      field :cumulative, pos_integer()
      field :duration, pos_integer()
      field :streak, pos_integer()
    end

    @spec from_event(map) :: __MODULE__.t()
    def from_event(event) do
      sub = event["resub"]

      %__MODULE__{
        sub_tier: SubTier.from_string(sub["sub_tier"]),
        cumulative: sub["cumulative_months"],
        duration: sub["duration_months"],
        streak: sub["streak_months"]
      }
    end
  end

  defmodule PrimeSub do
    typedstruct enforce: true do
      field :sub_tier, SubTier.t()
      field :duration, pos_integer()
    end

    @spec from_event(map) :: __MODULE__.t()
    def from_event(_event) do
      %__MODULE__{
        sub_tier: SubTier.from_string("prime"),
        duration: 1
      }
    end
  end

  defmodule SubGift do
    typedstruct enforce: true do
      field :community_gift_id, String.t() | nil
      field :user_id, String.t()
      field :user_login, String.t()
      field :user_display, String.t()
      field :sub_tier, SubTier.t()
      field :duration, pos_integer()
    end

    @spec from_event(map) :: __MODULE__.t()
    def from_event(event) do
      event = event["sub_gift"]

      %__MODULE__{
        community_gift_id: event["community_gift_id"],
        user_id: event["recipient_user_id"],
        user_login: event["recipient_user_login"],
        user_display: event["recipient_user_name"],
        sub_tier: SubTier.from_string(event["sub_tier"]),
        duration: event["duration_months"]
      }
    end
  end

  defmodule CommunitySubGift do
    #   id        string  The ID of the associated community gift.
    #   total     int     Number of subscriptions being gifted.
    #   sub_tier  string  The type of subscription plan being used. Possible values are:
    typedstruct enforce: true do
      field :id, String.t()
      field :total, pos_integer()
      field :sub_tier, SubTier.t()
    end

    @spec from_event(map) :: __MODULE__.t()
    def from_event(event) do
      community_gift = event["community_sub_gift"]

      %__MODULE__{
        id: community_gift["id"],
        total: community_gift["total"],
        sub_tier: SubTier.from_string(community_gift["sub_tier"])
      }
    end
  end

  defmodule GiftPaidUpgrade do
    typedstruct enforce: true do
      field :message, String.t()
      field :sub_tier, SubTier.t()
      field :duration, pos_integer()
    end

    @spec from_event(map) :: __MODULE__.t()
    def from_event(event) do
      %__MODULE__{
        message: event["system_message"],
        sub_tier: :tier_1,
        duration: 1
      }
    end
  end

  defmodule PrimePaidUpgrade do
    typedstruct enforce: true do
      field :message, String.t()
      field :sub_tier, SubTier.t()
      field :duration, pos_integer()
    end

    @spec from_event(map) :: __MODULE__.t()
    def from_event(event) do
      %__MODULE__{
        message: event["system_message"],
        sub_tier: :tier_1,
        duration: 1
      }
    end
  end

  typedstruct module: SelfSubscription, enforce: true do
    field :user, Twitch.User.t()

    field :subscription,
          Sub.t() | ReSub.t() | GiftPaidUpgrade.t() | PrimeSub.t() | PrimePaidUpgrade.t()
  end

  typedstruct module: GiftSubscription, enforce: true do
    field :gifter, Twitch.User.t()
    field :subscription, SubGift.t() | CommunitySubGift.t() | ReSub.t()
  end

  typedstruct enforce: true do
    field :message, String.t() | nil
    field :subscription, SelfSubscription.t() | GiftSubscription.t()
  end

  @spec from_event(map()) :: t()
  def from_event(event) do
    chatter_id = event["chatter_user_id"]
    chatter_login = event["chatter_user_login"]
    chatter_display = event["chatter_user_name"]

    chatter =
      Twitch.upsert_user(chatter_id, %{
        login: chatter_login,
        display: chatter_display
      })

    subscription =
      case event["notice_type"] do
        "sub" ->
          %SelfSubscription{user: chatter, subscription: Sub.from_event(event)}

        "resub" ->
          case event["resub"] do
            %{"is_gift" => false, "is_prime" => false} ->
              %SelfSubscription{user: chatter, subscription: ReSub.from_event(event)}

            %{"is_gift" => false, "is_prime" => true} ->
              # TODO: Decide what I want to do with twitch prime...
              # %SelfSubscription{user: chatter, subscription: PrimeSub.from_event(event)}
              %SelfSubscription{user: chatter, subscription: ReSub.from_event(event)}

            %{
              "is_gift" => true,
              "gifter_user_id" => gifter_id,
              "gifter_user_login" => gifter_login,
              "gifter_user_name" => gifter_display
            }
            when is_binary(gifter_id) and is_binary(gifter_login) ->
              gifter =
                Twitch.upsert_user(gifter_id, %{
                  login: gifter_login,
                  display: gifter_display
                })

              %GiftSubscription{gifter: gifter, subscription: Sub.from_event(event)}

            _ ->
              # Fallback to just giving the resub to the chatter, should only happen with anonymous (I think)
              %SelfSubscription{user: chatter, subscription: ReSub.from_event(event)}
          end

        "sub_gift" ->
          # TODO: Think about what to do with community_gift_id, which means we've already "counted" this gift
          %GiftSubscription{gifter: chatter, subscription: SubGift.from_event(event)}

        "community_sub_gift" ->
          _ = %{
            "chatter_is_anonymous" => false,
            "chatter_user_id" => "581458942",
            "chatter_user_login" => "4wiru",
            "chatter_user_name" => "4wiru",
            "community_sub_gift" => %{
              "cumulative_total" => 1,
              "id" => "7830401059032350188",
              "sub_tier" => "1000",
              "total" => 1
            },
            "message" => %{"fragments" => [], "text" => ""},
            "message_id" => "d534269b-d71e-4ba5-91b5-c3010040d3d1",
            "notice_type" => "community_sub_gift"
          }

          %GiftSubscription{gifter: chatter, subscription: CommunitySubGift.from_event(event)}

        "gift_paid_upgrade" ->
          %SelfSubscription{user: chatter, subscription: GiftPaidUpgrade.from_event(event)}

        "prime_paid_upgrade" ->
          %SelfSubscription{user: chatter, subscription: PrimePaidUpgrade.from_event(event)}
      end

    %__MODULE__{
      message: event["message"]["text"],
      subscription: subscription
    }
  end

  def self_subscription(user, subscription, message \\ nil) do
    %__MODULE__{
      message: message,
      subscription: %SelfSubscription{
        user: user,
        subscription: subscription
      }
    }
  end
end
