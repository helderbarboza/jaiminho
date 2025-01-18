defmodule Jaiminho.Repo do
  use Ecto.Repo,
    otp_app: :jaiminho,
    adapter: Ecto.Adapters.Postgres
end
