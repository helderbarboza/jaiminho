defmodule JaiminhoWeb.LocationControllerTest do
  use JaiminhoWeb.ConnCase
  alias Jaiminho.Logistics
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
  end

  defp create_location do
    {:ok, location} = Logistics.create_location(%{name: "location"})
    location
  end
end
