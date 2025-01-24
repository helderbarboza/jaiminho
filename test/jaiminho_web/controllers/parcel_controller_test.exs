defmodule JaiminhoWeb.ParcelControllerTest do
  use JaiminhoWeb.ConnCase

  alias Jaiminho.Logistics

  @invalid_attrs %{description: nil, is_delivered: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    setup [:locations]

    test "renders a parcel", %{conn: conn} do
      %{id: id} = parcel = create_parcel()
      conn = get(conn, ~p"/api/parcels/#{parcel}")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
    end

    test "renders a parcel with associated movements ordered", %{conn: conn} do
      %{id: location_a_id} = location_a = create_location(%{name: "Location A"})
      %{id: location_b_id} = location_b = create_location(%{name: "Location B"})
      %{id: location_c_id} = location_c = create_location(%{name: "Location C"})

      %{id: parcel_id} =
        parcel =
        create_parcel(%{source_id: location_a.id, destination_id: location_c.id})

      {_parcel, _movements} = transfer_parcel(parcel.id, location_b.id)
      {_parcel, _movements} = transfer_parcel(parcel.id, location_c.id)

      conn = get(conn, ~p"/api/parcels/#{parcel}")

      assert %{
               "id" => ^parcel_id,
               "movements" => [
                 %{"location" => %{"id" => ^location_a_id}},
                 %{"location" => %{"id" => ^location_b_id}},
                 %{"location" => %{"id" => ^location_c_id}}
               ]
             } =
               json_response(conn, 200)["data"]
    end

    test "renders a parcel with cyclic paths", %{
      conn: conn,
      locations: [location_a, location_b, location_c, location_d | _]
    } do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c
      %{id: location_d_id} = location_d

      %{id: parcel_id} =
        parcel =
        create_parcel(%{source_id: location_a.id, destination_id: location_d.id})

      {_parcel, _movements} = transfer_parcel(parcel.id, location_b.id)
      {_parcel, _movements} = transfer_parcel(parcel.id, location_c.id)
      {_parcel, _movements} = transfer_parcel(parcel.id, location_b.id)
      {_parcel, _movements} = transfer_parcel(parcel.id, location_c.id)
      {_parcel, _movements} = transfer_parcel(parcel.id, location_d.id)

      conn = get(conn, ~p"/api/parcels/#{parcel}")

      assert %{
               "id" => ^parcel_id,
               "movements" => [
                 %{"location" => %{"id" => ^location_a_id}},
                 %{"location" => %{"id" => ^location_b_id}},
                 %{"location" => %{"id" => ^location_c_id}},
                 %{"location" => %{"id" => ^location_b_id}},
                 %{"location" => %{"id" => ^location_c_id}},
                 %{"location" => %{"id" => ^location_d_id}}
               ]
             } =
               json_response(conn, 200)["data"]
    end
  end

  describe "create" do
    setup [:locations]

    test "renders parcel when data is valid", %{conn: conn} do
      %{id: source_id} = create_location(%{name: "Campinas - SP"})
      %{id: destination_id} = create_location(%{name: "Rio de Janeiro - RJ"})

      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{
            description: "Toothbrush",
            source_id: source_id,
            destination_id: destination_id
          }
        )

      assert %{
               "id" => _id,
               "description" => "Toothbrush",
               "is_delivered" => false,
               "source" => %{"id" => ^source_id},
               "destination" => %{"id" => ^destination_id},
               "movements" => [
                 %{"location" => %{"id" => ^source_id, "name" => "Campinas - SP"}}
               ]
             } = json_response(conn, 201)["data"]
    end

    test "renders errors when the 'source' and 'destination' locations are the same", %{
      conn: conn
    } do
      %{id: location_id} = create_location()

      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: location_id, destination_id: location_id, description: "Bookcase"}
        )

      body = json_response(conn, 422)
      assert "must be not equal to source_id's change value" in body["errors"]["destination_id"]
    end

    test "renders errors when the 'source' location doesn't exist", %{
      conn: conn,
      locations: [destination | _]
    } do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: 0, destination_id: destination.id, description: "Jukebox"}
        )

      assert json_response(conn, 422)["errors"]["source_id"] != []
    end

    test "renders errors when the 'destination' location doesn't exist", %{
      conn: conn,
      locations: [source | _]
    } do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{destination_id: 0, source_id: source.id, description: "Gramophone"}
        )

      assert json_response(conn, 422)["errors"]["destination_id"] != []
    end

    test "renders errors when the 'source' is missing", %{
      conn: conn,
      locations: [destination | _]
    } do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{destination_id: destination.id, description: "Coffee table"}
        )

      assert json_response(conn, 422)["errors"]["source_id"] != []
    end

    test "renders errors when the 'destination' is missing", %{
      conn: conn,
      locations: [source | _]
    } do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: source.id, description: "Pinball machine"}
        )

      assert json_response(conn, 422)["errors"]["destination_id"] != []
    end

    test "renders errors when 'description' is missing", %{
      conn: conn,
      locations: [source, destination | _]
    } do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: source.id, destination_id: destination.id}
        )

      assert json_response(conn, 422)["errors"]["description"] != []
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/parcels", parcel: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "transfer" do
    test "renders parcel with its updated location", %{conn: conn} do
      %{id: source_id} = create_location(%{name: "São Paulo - SP"})
      %{id: destination_id} = create_location(%{name: "Manaus - AM"})

      %{id: parcel_id} =
        parcel =
        create_parcel(%{
          description: "Washing machine",
          source_id: source_id,
          destination_id: destination_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: destination_id})

      assert %{
               "id" => ^parcel_id,
               "description" => "Washing machine",
               "is_delivered" => true,
               "movements" => [
                 %{"location" => %{"id" => ^source_id}},
                 %{"location" => %{"id" => ^destination_id}}
               ]
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_parcel(attrs \\ %{}) do
    {:ok, parcel} =
      attrs
      |> Enum.into(%{
        description: "my parcel",
        is_delivered: false,
        source_id: create_location().id,
        destination_id: create_location().id
      })
      |> Logistics.create_parcel()

    parcel
  end

  defp transfer_parcel(parcel_id, to_location_id) do
    {:ok, parcel, movements} = Logistics.transfer_parcel(parcel_id, to_location_id)

    {parcel, movements}
  end

  defp create_location(attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{name: "My location"})
      |> Logistics.create_location()

    location
  end

  defp locations(_context) do
    [
      locations: [
        create_location(%{name: "Location A"}),
        create_location(%{name: "Location B"}),
        create_location(%{name: "Location C"}),
        create_location(%{name: "Location D"})
      ]
    ]
  end
end
