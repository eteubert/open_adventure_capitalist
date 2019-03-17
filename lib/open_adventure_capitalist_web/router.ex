defmodule OpenAdventureCapitalistWeb.Router do
  use OpenAdventureCapitalistWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_layout, {OpenAdventureCapitalistWeb.LayoutView, :app}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OpenAdventureCapitalistWeb do
    pipe_through :browser

    live("/", GameLive)
  end

  # Other scopes may use custom stacks.
  # scope "/api", OpenAdventureCapitalistWeb do
  #   pipe_through :api
  # end
end
