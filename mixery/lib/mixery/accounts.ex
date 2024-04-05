defmodule Mixery.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Mixery.Repo

  alias Mixery.Accounts.{Twitch, TwitchToken, TwitchNotifier}

  ## Database getters

  @doc """
  Gets a twitch by email.

  ## Examples

      iex> get_twitch_by_email("foo@example.com")
      %Twitch{}

      iex> get_twitch_by_email("unknown@example.com")
      nil

  """
  def get_twitch_by_email(email) when is_binary(email) do
    Repo.get_by(Twitch, email: email)
  end

  @doc """
  Gets a twitch by email and password.

  ## Examples

      iex> get_twitch_by_email_and_password("foo@example.com", "correct_password")
      %Twitch{}

      iex> get_twitch_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_twitch_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    twitch = Repo.get_by(Twitch, email: email)
    if Twitch.valid_password?(twitch, password), do: twitch
  end

  @doc """
  Gets a single twitch.

  Raises `Ecto.NoResultsError` if the Twitch does not exist.

  ## Examples

      iex> get_twitch!(123)
      %Twitch{}

      iex> get_twitch!(456)
      ** (Ecto.NoResultsError)

  """
  def get_twitch!(id), do: Repo.get!(Twitch, id)

  ## Twitch registration

  @doc """
  Registers a twitch.

  ## Examples

      iex> register_twitch(%{field: value})
      {:ok, %Twitch{}}

      iex> register_twitch(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_twitch(attrs) do
    %Twitch{}
    |> Twitch.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking twitch changes.

  ## Examples

      iex> change_twitch_registration(twitch)
      %Ecto.Changeset{data: %Twitch{}}

  """
  def change_twitch_registration(%Twitch{} = twitch, attrs \\ %{}) do
    Twitch.registration_changeset(twitch, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the twitch email.

  ## Examples

      iex> change_twitch_email(twitch)
      %Ecto.Changeset{data: %Twitch{}}

  """
  def change_twitch_email(twitch, attrs \\ %{}) do
    Twitch.email_changeset(twitch, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_twitch_email(twitch, "valid password", %{email: ...})
      {:ok, %Twitch{}}

      iex> apply_twitch_email(twitch, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_twitch_email(twitch, password, attrs) do
    twitch
    |> Twitch.email_changeset(attrs)
    |> Twitch.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the twitch email using the given token.

  If the token matches, the twitch email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_twitch_email(twitch, token) do
    context = "change:#{twitch.email}"

    with {:ok, query} <- TwitchToken.verify_change_email_token_query(token, context),
         %TwitchToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(twitch_email_multi(twitch, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp twitch_email_multi(twitch, email, context) do
    changeset =
      twitch
      |> Twitch.email_changeset(%{email: email})
      |> Twitch.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:twitch, changeset)
    |> Ecto.Multi.delete_all(:tokens, TwitchToken.by_twitch_and_contexts_query(twitch, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given twitch.

  ## Examples

      iex> deliver_twitch_update_email_instructions(twitch, current_email, &url(~p"/twitch_accounts/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_twitch_update_email_instructions(%Twitch{} = twitch, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, twitch_token} = TwitchToken.build_email_token(twitch, "change:#{current_email}")

    Repo.insert!(twitch_token)
    TwitchNotifier.deliver_update_email_instructions(twitch, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the twitch password.

  ## Examples

      iex> change_twitch_password(twitch)
      %Ecto.Changeset{data: %Twitch{}}

  """
  def change_twitch_password(twitch, attrs \\ %{}) do
    Twitch.password_changeset(twitch, attrs, hash_password: false)
  end

  @doc """
  Updates the twitch password.

  ## Examples

      iex> update_twitch_password(twitch, "valid password", %{password: ...})
      {:ok, %Twitch{}}

      iex> update_twitch_password(twitch, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_twitch_password(twitch, password, attrs) do
    changeset =
      twitch
      |> Twitch.password_changeset(attrs)
      |> Twitch.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:twitch, changeset)
    |> Ecto.Multi.delete_all(:tokens, TwitchToken.by_twitch_and_contexts_query(twitch, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{twitch: twitch}} -> {:ok, twitch}
      {:error, :twitch, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_twitch_session_token(twitch) do
    {token, twitch_token} = TwitchToken.build_session_token(twitch)
    Repo.insert!(twitch_token)
    token
  end

  @doc """
  Gets the twitch with the given signed token.
  """
  def get_twitch_by_session_token(token) do
    {:ok, query} = TwitchToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_twitch_session_token(token) do
    Repo.delete_all(TwitchToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given twitch.

  ## Examples

      iex> deliver_twitch_confirmation_instructions(twitch, &url(~p"/twitch_accounts/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_twitch_confirmation_instructions(confirmed_twitch, &url(~p"/twitch_accounts/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_twitch_confirmation_instructions(%Twitch{} = twitch, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if twitch.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, twitch_token} = TwitchToken.build_email_token(twitch, "confirm")
      Repo.insert!(twitch_token)
      TwitchNotifier.deliver_confirmation_instructions(twitch, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a twitch by the given token.

  If the token matches, the twitch account is marked as confirmed
  and the token is deleted.
  """
  def confirm_twitch(token) do
    with {:ok, query} <- TwitchToken.verify_email_token_query(token, "confirm"),
         %Twitch{} = twitch <- Repo.one(query),
         {:ok, %{twitch: twitch}} <- Repo.transaction(confirm_twitch_multi(twitch)) do
      {:ok, twitch}
    else
      _ -> :error
    end
  end

  defp confirm_twitch_multi(twitch) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:twitch, Twitch.confirm_changeset(twitch))
    |> Ecto.Multi.delete_all(:tokens, TwitchToken.by_twitch_and_contexts_query(twitch, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given twitch.

  ## Examples

      iex> deliver_twitch_reset_password_instructions(twitch, &url(~p"/twitch_accounts/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_twitch_reset_password_instructions(%Twitch{} = twitch, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, twitch_token} = TwitchToken.build_email_token(twitch, "reset_password")
    Repo.insert!(twitch_token)
    TwitchNotifier.deliver_reset_password_instructions(twitch, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the twitch by reset password token.

  ## Examples

      iex> get_twitch_by_reset_password_token("validtoken")
      %Twitch{}

      iex> get_twitch_by_reset_password_token("invalidtoken")
      nil

  """
  def get_twitch_by_reset_password_token(token) do
    with {:ok, query} <- TwitchToken.verify_email_token_query(token, "reset_password"),
         %Twitch{} = twitch <- Repo.one(query) do
      twitch
    else
      _ -> nil
    end
  end

  @doc """
  Resets the twitch password.

  ## Examples

      iex> reset_twitch_password(twitch, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Twitch{}}

      iex> reset_twitch_password(twitch, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_twitch_password(twitch, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:twitch, Twitch.password_changeset(twitch, attrs))
    |> Ecto.Multi.delete_all(:tokens, TwitchToken.by_twitch_and_contexts_query(twitch, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{twitch: twitch}} -> {:ok, twitch}
      {:error, :twitch, changeset, _} -> {:error, changeset}
    end
  end
end
