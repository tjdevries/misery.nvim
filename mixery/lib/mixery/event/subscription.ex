defmodule Mixery.Event.Subscription do
  alias Mixery.Twitch
  alias Mixery.Twitch.SubTier

  defmodule SelfSubscription do
    @type t :: %__MODULE__{
            user: Twitch.User.t(),
            subscription:
              Sub.t() | ReSub.t() | GiftPaidUpgrade.t() | PrimeSub.t() | PrimePaidUpgrade.t()
          }

    defstruct [:user, :subscription]
  end

  defmodule GiftSubscription do
    @type t :: %__MODULE__{
            gifter: Twitch.User.t(),
            subscription: SubGift.t() | CommunitySubGift.t() | ReSub.t()
          }

    defstruct [:gifter, :subscription]
  end

  @type t :: SelfSubscription.t() | GiftSubscription.t()

  defmodule Sub do
    @type t :: %__MODULE__{
            sub_tier: SubTier.t(),
            duration: pos_integer()
          }

    defstruct [:sub_tier, :duration]

    def from_event(event) do
      sub = event["sub"]

      %__MODULE__{
        sub_tier: SubTier.from_string(sub["sub_tier"]),
        duration: sub["duration_months"]
      }
    end
  end

  defmodule ReSub do
    @type t :: %__MODULE__{
            sub_tier: SubTier.t(),
            cumulative: pos_integer(),
            duration: pos_integer(),
            streak: pos_integer()
          }

    defstruct [:sub_tier, :cumulative, :duration, :streak]

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
    @type t :: %__MODULE__{sub_tier: SubTier.t(), duration: pos_integer()}
    defstruct [:sub_tier, :duration]

    def from_event(_event) do
      %__MODULE__{
        sub_tier: SubTier.from_string("prime"),
        duration: 1
      }
    end
  end

  defmodule SubGift do
    @type t :: %__MODULE__{
            community_gift_id: String.t() | nil,
            user_id: String.t(),
            user_login: String.t(),
            sub_tier: SubTier.t(),
            duration: pos_integer()
          }

    # recipient_user_id	string	The user ID of the subscription gift recipient.
    # recipient_user_login	string	The user login of the subscription gift recipient.
    # duration_months	int	The number of months the subscription is for.
    # sub_tier	string	The type of subscription plan being used. Possible values are:
    defstruct [:community_gift_id, :user_id, :user_login, :sub_tier, duration: 1]

    def from_event(event) do
      event = event["sub_gift"]

      %__MODULE__{
        community_gift_id: event["recipient_id"],
        user_id: event["recipient_id"],
        user_login: event["recipient_login"],
        sub_tier: SubTier.from_string(event["sub_tier"]),
        duration: event["duration_months"]
      }
    end
  end

  defmodule CommunitySubGift do
    @type t :: %__MODULE__{
            id: String.t(),
            total: pos_integer(),
            sub_tier: SubTier.t()
          }

    #   id        string  The ID of the associated community gift.
    #   total     int     Number of subscriptions being gifted.
    #   sub_tier  string  The type of subscription plan being used. Possible values are:
    defstruct [:id, :total, :sub_tier]

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
    @type t :: %__MODULE__{
            message: String.t(),
            sub_tier: SubTier.t(),
            duration: pos_integer()
          }

    defstruct [:message, :sub_tier, :duration]

    def from_event(event) do
      %__MODULE__{
        message: event["system_message"],
        sub_tier: :tier_1,
        duration: 1
      }
    end
  end

  defmodule PrimePaidUpgrade do
    @type t :: %__MODULE__{
            message: String.t(),
            sub_tier: SubTier.t(),
            duration: pos_integer()
          }

    defstruct [:message, :sub_tier, :duration]

    def from_event(event) do
      %__MODULE__{
        message: event["system_message"],
        sub_tier: :tier_1,
        duration: 1
      }
    end
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
  end
end
