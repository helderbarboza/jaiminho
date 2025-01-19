defmodule JaiminhoWeb.Router do
  use JaiminhoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", JaiminhoWeb do
    pipe_through :api

    resources "/locations", LocationController, only: [:show]
    resources "/parcels", ParcelController, only: [:show, :create]
    post "/parcels/:id/transfer", ParcelController, :transfer
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:jaiminho, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: JaiminhoWeb.Telemetry
    end
  end
end
