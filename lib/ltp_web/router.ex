defmodule LTPWeb.Router do
  use LTPWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LTPWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LTPWeb do
    pipe_through :browser

    get "/login/:token", SessionController, :login

    live_session :default do
      live "/", Tournament.ShowLive, :show
      live "/tournament/:id", Tournament.ShowLive, :show
      live "/tournament/:id/add_player", Tournament.ShowLive, :add_player
      live "/tournament/:tournament_id/leaderboards/:game_id", Tournament.LeaderboardLive, :show
      live "/tournament/:tournament_id/leaderboards/:game_id/add_score", Tournament.LeaderboardLive, :add_score
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", LTPWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ltp, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
