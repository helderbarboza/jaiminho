defmodule JaiminhoWeb.ParcelController do
  use JaiminhoWeb, :controller

  alias Jaiminho.Logistics
  alias Jaiminho.Logistics.Parcel

  action_fallback JaiminhoWeb.FallbackController

  def create(conn, %{"parcel" => parcel_params}) do
    with {:ok, %Parcel{} = parcel} <- Logistics.create_parcel(parcel_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/parcels/#{parcel}")
      |> render(:show, parcel: parcel)
    end
  end

  def show(conn, %{"id" => id}) do
    parcel = Logistics.get_parcel!(id)
    render(conn, :show, parcel: parcel)
  end
end
