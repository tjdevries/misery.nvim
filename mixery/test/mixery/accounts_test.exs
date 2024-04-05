defmodule Mixery.AccountsTest do
  use Mixery.DataCase

  alias Mixery.Accounts

  import Mixery.AccountsFixtures
  alias Mixery.Accounts.{Twitch, TwitchToken}

  describe "get_twitch_by_email/1" do
    test "does not return the twitch if the email does not exist" do
      refute Accounts.get_twitch_by_email("unknown@example.com")
    end

    test "returns the twitch if the email exists" do
      %{id: id} = twitch = twitch_fixture()
      assert %Twitch{id: ^id} = Accounts.get_twitch_by_email(twitch.email)
    end
  end

  describe "get_twitch_by_email_and_password/2" do
    test "does not return the twitch if the email does not exist" do
      refute Accounts.get_twitch_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the twitch if the password is not valid" do
      twitch = twitch_fixture()
      refute Accounts.get_twitch_by_email_and_password(twitch.email, "invalid")
    end

    test "returns the twitch if the email and password are valid" do
      %{id: id} = twitch = twitch_fixture()

      assert %Twitch{id: ^id} =
               Accounts.get_twitch_by_email_and_password(twitch.email, valid_twitch_password())
    end
  end

  describe "get_twitch!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_twitch!(-1)
      end
    end

    test "returns the twitch with the given id" do
      %{id: id} = twitch = twitch_fixture()
      assert %Twitch{id: ^id} = Accounts.get_twitch!(twitch.id)
    end
  end

  describe "register_twitch/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_twitch(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_twitch(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_twitch(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = twitch_fixture()
      {:error, changeset} = Accounts.register_twitch(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_twitch(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers twitch_accounts with a hashed password" do
      email = unique_twitch_email()
      {:ok, twitch} = Accounts.register_twitch(valid_twitch_attributes(email: email))
      assert twitch.email == email
      assert is_binary(twitch.hashed_password)
      assert is_nil(twitch.confirmed_at)
      assert is_nil(twitch.password)
    end
  end

  describe "change_twitch_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_twitch_registration(%Twitch{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_twitch_email()
      password = valid_twitch_password()

      changeset =
        Accounts.change_twitch_registration(
          %Twitch{},
          valid_twitch_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_twitch_email/2" do
    test "returns a twitch changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_twitch_email(%Twitch{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_twitch_email/3" do
    setup do
      %{twitch: twitch_fixture()}
    end

    test "requires email to change", %{twitch: twitch} do
      {:error, changeset} = Accounts.apply_twitch_email(twitch, valid_twitch_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{twitch: twitch} do
      {:error, changeset} =
        Accounts.apply_twitch_email(twitch, valid_twitch_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{twitch: twitch} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_twitch_email(twitch, valid_twitch_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{twitch: twitch} do
      %{email: email} = twitch_fixture()
      password = valid_twitch_password()

      {:error, changeset} = Accounts.apply_twitch_email(twitch, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{twitch: twitch} do
      {:error, changeset} =
        Accounts.apply_twitch_email(twitch, "invalid", %{email: unique_twitch_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{twitch: twitch} do
      email = unique_twitch_email()
      {:ok, twitch} = Accounts.apply_twitch_email(twitch, valid_twitch_password(), %{email: email})
      assert twitch.email == email
      assert Accounts.get_twitch!(twitch.id).email != email
    end
  end

  describe "deliver_twitch_update_email_instructions/3" do
    setup do
      %{twitch: twitch_fixture()}
    end

    test "sends token through notification", %{twitch: twitch} do
      token =
        extract_twitch_token(fn url ->
          Accounts.deliver_twitch_update_email_instructions(twitch, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert twitch_token = Repo.get_by(TwitchToken, token: :crypto.hash(:sha256, token))
      assert twitch_token.twitch_id == twitch.id
      assert twitch_token.sent_to == twitch.email
      assert twitch_token.context == "change:current@example.com"
    end
  end

  describe "update_twitch_email/2" do
    setup do
      twitch = twitch_fixture()
      email = unique_twitch_email()

      token =
        extract_twitch_token(fn url ->
          Accounts.deliver_twitch_update_email_instructions(%{twitch | email: email}, twitch.email, url)
        end)

      %{twitch: twitch, token: token, email: email}
    end

    test "updates the email with a valid token", %{twitch: twitch, token: token, email: email} do
      assert Accounts.update_twitch_email(twitch, token) == :ok
      changed_twitch = Repo.get!(Twitch, twitch.id)
      assert changed_twitch.email != twitch.email
      assert changed_twitch.email == email
      assert changed_twitch.confirmed_at
      assert changed_twitch.confirmed_at != twitch.confirmed_at
      refute Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end

    test "does not update email with invalid token", %{twitch: twitch} do
      assert Accounts.update_twitch_email(twitch, "oops") == :error
      assert Repo.get!(Twitch, twitch.id).email == twitch.email
      assert Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end

    test "does not update email if twitch email changed", %{twitch: twitch, token: token} do
      assert Accounts.update_twitch_email(%{twitch | email: "current@example.com"}, token) == :error
      assert Repo.get!(Twitch, twitch.id).email == twitch.email
      assert Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end

    test "does not update email if token expired", %{twitch: twitch, token: token} do
      {1, nil} = Repo.update_all(TwitchToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_twitch_email(twitch, token) == :error
      assert Repo.get!(Twitch, twitch.id).email == twitch.email
      assert Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end
  end

  describe "change_twitch_password/2" do
    test "returns a twitch changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_twitch_password(%Twitch{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_twitch_password(%Twitch{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_twitch_password/3" do
    setup do
      %{twitch: twitch_fixture()}
    end

    test "validates password", %{twitch: twitch} do
      {:error, changeset} =
        Accounts.update_twitch_password(twitch, valid_twitch_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{twitch: twitch} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_twitch_password(twitch, valid_twitch_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{twitch: twitch} do
      {:error, changeset} =
        Accounts.update_twitch_password(twitch, "invalid", %{password: valid_twitch_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{twitch: twitch} do
      {:ok, twitch} =
        Accounts.update_twitch_password(twitch, valid_twitch_password(), %{
          password: "new valid password"
        })

      assert is_nil(twitch.password)
      assert Accounts.get_twitch_by_email_and_password(twitch.email, "new valid password")
    end

    test "deletes all tokens for the given twitch", %{twitch: twitch} do
      _ = Accounts.generate_twitch_session_token(twitch)

      {:ok, _} =
        Accounts.update_twitch_password(twitch, valid_twitch_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end
  end

  describe "generate_twitch_session_token/1" do
    setup do
      %{twitch: twitch_fixture()}
    end

    test "generates a token", %{twitch: twitch} do
      token = Accounts.generate_twitch_session_token(twitch)
      assert twitch_token = Repo.get_by(TwitchToken, token: token)
      assert twitch_token.context == "session"

      # Creating the same token for another twitch should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%TwitchToken{
          token: twitch_token.token,
          twitch_id: twitch_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_twitch_by_session_token/1" do
    setup do
      twitch = twitch_fixture()
      token = Accounts.generate_twitch_session_token(twitch)
      %{twitch: twitch, token: token}
    end

    test "returns twitch by token", %{twitch: twitch, token: token} do
      assert session_twitch = Accounts.get_twitch_by_session_token(token)
      assert session_twitch.id == twitch.id
    end

    test "does not return twitch for invalid token" do
      refute Accounts.get_twitch_by_session_token("oops")
    end

    test "does not return twitch for expired token", %{token: token} do
      {1, nil} = Repo.update_all(TwitchToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_twitch_by_session_token(token)
    end
  end

  describe "delete_twitch_session_token/1" do
    test "deletes the token" do
      twitch = twitch_fixture()
      token = Accounts.generate_twitch_session_token(twitch)
      assert Accounts.delete_twitch_session_token(token) == :ok
      refute Accounts.get_twitch_by_session_token(token)
    end
  end

  describe "deliver_twitch_confirmation_instructions/2" do
    setup do
      %{twitch: twitch_fixture()}
    end

    test "sends token through notification", %{twitch: twitch} do
      token =
        extract_twitch_token(fn url ->
          Accounts.deliver_twitch_confirmation_instructions(twitch, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert twitch_token = Repo.get_by(TwitchToken, token: :crypto.hash(:sha256, token))
      assert twitch_token.twitch_id == twitch.id
      assert twitch_token.sent_to == twitch.email
      assert twitch_token.context == "confirm"
    end
  end

  describe "confirm_twitch/1" do
    setup do
      twitch = twitch_fixture()

      token =
        extract_twitch_token(fn url ->
          Accounts.deliver_twitch_confirmation_instructions(twitch, url)
        end)

      %{twitch: twitch, token: token}
    end

    test "confirms the email with a valid token", %{twitch: twitch, token: token} do
      assert {:ok, confirmed_twitch} = Accounts.confirm_twitch(token)
      assert confirmed_twitch.confirmed_at
      assert confirmed_twitch.confirmed_at != twitch.confirmed_at
      assert Repo.get!(Twitch, twitch.id).confirmed_at
      refute Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end

    test "does not confirm with invalid token", %{twitch: twitch} do
      assert Accounts.confirm_twitch("oops") == :error
      refute Repo.get!(Twitch, twitch.id).confirmed_at
      assert Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end

    test "does not confirm email if token expired", %{twitch: twitch, token: token} do
      {1, nil} = Repo.update_all(TwitchToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_twitch(token) == :error
      refute Repo.get!(Twitch, twitch.id).confirmed_at
      assert Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end
  end

  describe "deliver_twitch_reset_password_instructions/2" do
    setup do
      %{twitch: twitch_fixture()}
    end

    test "sends token through notification", %{twitch: twitch} do
      token =
        extract_twitch_token(fn url ->
          Accounts.deliver_twitch_reset_password_instructions(twitch, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert twitch_token = Repo.get_by(TwitchToken, token: :crypto.hash(:sha256, token))
      assert twitch_token.twitch_id == twitch.id
      assert twitch_token.sent_to == twitch.email
      assert twitch_token.context == "reset_password"
    end
  end

  describe "get_twitch_by_reset_password_token/1" do
    setup do
      twitch = twitch_fixture()

      token =
        extract_twitch_token(fn url ->
          Accounts.deliver_twitch_reset_password_instructions(twitch, url)
        end)

      %{twitch: twitch, token: token}
    end

    test "returns the twitch with valid token", %{twitch: %{id: id}, token: token} do
      assert %Twitch{id: ^id} = Accounts.get_twitch_by_reset_password_token(token)
      assert Repo.get_by(TwitchToken, twitch_id: id)
    end

    test "does not return the twitch with invalid token", %{twitch: twitch} do
      refute Accounts.get_twitch_by_reset_password_token("oops")
      assert Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end

    test "does not return the twitch if token expired", %{twitch: twitch, token: token} do
      {1, nil} = Repo.update_all(TwitchToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_twitch_by_reset_password_token(token)
      assert Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end
  end

  describe "reset_twitch_password/2" do
    setup do
      %{twitch: twitch_fixture()}
    end

    test "validates password", %{twitch: twitch} do
      {:error, changeset} =
        Accounts.reset_twitch_password(twitch, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{twitch: twitch} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_twitch_password(twitch, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{twitch: twitch} do
      {:ok, updated_twitch} = Accounts.reset_twitch_password(twitch, %{password: "new valid password"})
      assert is_nil(updated_twitch.password)
      assert Accounts.get_twitch_by_email_and_password(twitch.email, "new valid password")
    end

    test "deletes all tokens for the given twitch", %{twitch: twitch} do
      _ = Accounts.generate_twitch_session_token(twitch)
      {:ok, _} = Accounts.reset_twitch_password(twitch, %{password: "new valid password"})
      refute Repo.get_by(TwitchToken, twitch_id: twitch.id)
    end
  end

  describe "inspect/2 for the Twitch module" do
    test "does not include password" do
      refute inspect(%Twitch{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
