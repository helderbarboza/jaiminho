defmodule JaiminhoWeb.LocationController do
  use JaiminhoWeb, :controller

  alias Jaiminho.Logistics

  action_fallback JaiminhoWeb.FallbackController

  def show(conn, %{"id" => id}) do
    location = Logistics.get_location!(id)
    render(conn, :show, location: location)
  end
end
