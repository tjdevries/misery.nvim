defmodule Mixery.Repo do
  use Ecto.Repo,
    otp_app: :mixery,
    adapter: Ecto.Adapters.Postgres
end
