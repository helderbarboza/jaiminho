defmodule JaiminhoWeb.LocationControllerTest do
  use JaiminhoWeb.ConnCase
  import Jaiminho.LogisticsFixtures
  alias Jaiminho.Logistics.Location

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    test "renders a location", %{conn: conn} do
      %Location{id: id, name: name} = location = create_location()
      conn = get(conn, ~p"/api/locations/#{location}")
      assert %{"id" => ^id, "name" => ^name, "parcels" => []} = json_response(conn, 200)["data"]
    end

    test "retrieves location details and parcels present in that location", %{conn: conn} do
      %{id: location_a_id, name: location_a_name} = location_a = create_location()
      location_b = create_location()

      %{id: parcel_a_id} =
        create_parcel(%{
          description: "Pepper mill",
          source_id: location_a.id,
          destination_id: location_b.id
        })

      %{id: parcel_b_id} =
        create_parcel(%{
          description: "Meat grinder",
          source_id: location_a.id,
          destination_id: location_b.id
        })

      conn = get(conn, ~p"/api/locations/#{location_a}")

      assert %{
               "id" => ^location_a_id,
               "name" => ^location_a_name,
               "parcels" => [
                 %{"id" => ^parcel_a_id},
                 %{"id" => ^parcel_b_id}
               ]
             } = json_response(conn, 200)["data"]
    end

    test "includes only parcels that are currently at the location", %{conn: conn} do
      location_a = create_location()
      location_b = create_location()

      %{id: parcel_id} =
        parcel =
        create_parcel(%{
          description: "Skillet",
          source_id: location_a.id,
          destination_id: location_b.id
        })

      conn = get(conn, ~p"/api/locations/#{location_a}")
      assert [%{"id" => ^parcel_id}] = json_response(conn, 200)["data"]["parcels"]

      transfer_parcel(parcel, location_b.id)

      conn = get(conn, ~p"/api/locations/#{location_a}")
      assert [] = json_response(conn, 200)["data"]["parcels"]
    end
  end
end
