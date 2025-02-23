defmodule Ctrack.Repo do
  use Ecto.Repo,
    otp_app: :ctrack,
    adapter: Ecto.Adapters.Postgres
end
