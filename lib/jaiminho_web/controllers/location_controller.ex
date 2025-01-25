defmodule JaiminhoWeb.LocationController do
  use JaiminhoWeb, :controller

  alias Jaiminho.Logistics

  action_fallback JaiminhoWeb.FallbackController

  def show(conn, %{"id" => id}) do
    location = Logistics.get_location!(id)
    parcels = Logistics.list_parcels_at_location(id)
    render(conn, :show, location: location, parcels: parcels)
  end
end
