defmodule JaiminhoWeb.LocationControllerTest do
  use JaiminhoWeb.ConnCase

  import Jaiminho.LogisticsFixtures

  alias Jaiminho.Logistics.Location

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    setup [:create_location]

    test "renders a location", %{conn: conn, location: %Location{id: id}} do
      conn = get(conn, ~p"/api/locations/#{id}")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
    end
  end

  defp create_location(_) do
    location = location_fixture()
    %{location: location}
  end
end
