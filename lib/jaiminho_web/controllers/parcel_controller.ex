defmodule JaiminhoWeb.ParcelController do
  use JaiminhoWeb, :controller

  alias Jaiminho.Logistics
  alias Jaiminho.Logistics.Parcel

  action_fallback JaiminhoWeb.FallbackController

  def create(conn, %{"parcel" => parcel_params}) do
    with {:ok, %Parcel{} = parcel} <- Logistics.create_parcel(parcel_params) do
      movements = Logistics.list_movements_of_parcel(parcel.id)

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/parcels/#{parcel}")
      |> render(:show, parcel: parcel, movements: movements)
    end
  end

  def show(conn, %{"id" => id}) do
    parcel = Logistics.get_parcel!(id)
    movements = Logistics.list_movements_of_parcel(id)
    render(conn, :show, parcel: parcel, movements: movements)
  end

  def transfer(conn, %{"id" => id, "location_id" => location_id}) do
    with {:ok, %Parcel{} = parcel, movements} <- Logistics.transfer_parcel(id, location_id) do
      render(conn, :show, parcel: parcel, movements: movements)
    end
  end
end
