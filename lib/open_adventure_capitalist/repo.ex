defmodule OpenAdventureCapitalist.Repo do
  use Ecto.Repo,
    otp_app: :open_adventure_capitalist,
    adapter: Ecto.Adapters.Postgres
end
