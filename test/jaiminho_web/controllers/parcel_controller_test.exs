defmodule JaiminhoWeb.ParcelControllerTest do
  use JaiminhoWeb.ConnCase

  alias Jaiminho.Logistics

  @create_attrs %{
    description: "some description",
    is_delivered: true
  }
  @invalid_attrs %{description: nil, is_delivered: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    test "renders a parcel", %{conn: conn} do
      %{id: id} = parcel = create_parcel()
      conn = get(conn, ~p"/api/parcels/#{parcel}")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
    end
  end

  describe "create parcel" do
    test "renders parcel when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/parcels", parcel: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/parcels/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some description",
               "is_delivered" => true
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/parcels", parcel: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  defp create_location() do
    {:ok, location} = Logistics.create_location(%{name: "location"})
    location
  end

  defp create_parcel(attrs \\ %{}) do
    source = create_location()
    destination = create_location()

    {:ok, parcel} =
      attrs
      |> Enum.into(%{
        description: "my parcel",
        is_delivered: false,
        source_id: source.id,
        destination_id: destination.id
      })
      |> Logistics.create_parcel()

    parcel
  end
end
