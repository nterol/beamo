defmodule Beamo.Repo do
  use Ecto.Repo,
    otp_app: :beamo,
    adapter: Ecto.Adapters.Postgres
end
