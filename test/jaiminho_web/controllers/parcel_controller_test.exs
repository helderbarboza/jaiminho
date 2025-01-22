defmodule JaiminhoWeb.ParcelControllerTest do
  use JaiminhoWeb.ConnCase

  alias Jaiminho.Logistics

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
      %{id: source_id} = source = create_location(%{name: "São Paulo - SP"})
      destination = create_location(%{name: "Rio de Janeiro - RJ"})

      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{
            description: "Toothbrush",
            source_id: source.id,
            destination_id: destination.id
          }
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/parcels/#{id}")

      assert %{
               "id" => ^id,
               "description" => "Toothbrush",
               "is_delivered" => false,
               "movements" => [
                 %{
                   "location" => %{
                     "id" => ^source_id,
                     "name" => "São Paulo - SP"
                   }
                 }
               ]
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/parcels", parcel: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  defp create_location(attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{
        name: "My location"
      })
      |> Logistics.create_location()

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
