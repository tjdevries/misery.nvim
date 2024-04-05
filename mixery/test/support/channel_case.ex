defmodule MixeryWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MixeryWeb.ChannelCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import MixeryWeb.ChannelCase

      # The default endpoint for testing
      @endpoint MixeryWeb.Endpoint
    end
  end

  setup tags do
    Mixery.DataCase.setup_sandbox(tags)

    # # Explicitly get a connection before each test
    # :ok = Ecto.Adapters.SQL.Sandbox.checkout(Mixery.Repo)
    # # Setting the shared mode must be done only after checkout
    # Ecto.Adapters.SQL.Sandbox.mode(Mixery.Repo, {:shared, self()})

    :ok
  end
end
