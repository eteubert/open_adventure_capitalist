# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :open_adventure_capitalist,
  ecto_repos: [OpenAdventureCapitalist.Repo]

# Configures the endpoint
config :open_adventure_capitalist, OpenAdventureCapitalistWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "5iRJIz0s9FiHmt8EllT1T+RrpVPUw5/QMY8z0cZ8oTRt8EctiqTiJC8LBuwk3DDg",
  render_errors: [view: OpenAdventureCapitalistWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: OpenAdventureCapitalist.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "lMUpWUnsCAMDf5yiVNAGI+GSTBB4qYjf"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix,
  template_engines: [leex: Phoenix.LiveView.Engine]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
