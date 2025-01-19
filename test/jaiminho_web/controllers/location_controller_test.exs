defmodule JaiminhoWeb.LocationControllerTest do
  use JaiminhoWeb.ConnCase

  alias Jaiminho.Logistics

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    test "renders a location", %{conn: conn} do
      %{id: id} = create_location()
      conn = get(conn, ~p"/api/locations/#{id}")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
    end
  end

  defp create_location() do
    {:ok, location} = Logistics.create_location(%{name: "location"})
    location
  end
end
