defmodule JaiminhoWeb.ParcelControllerTest do
  use JaiminhoWeb.ConnCase

  alias Jaiminho.Logistics

  @invalid_attrs %{description: nil, is_delivered: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    setup [:locations]

    test "renders a parcel", %{conn: conn, locations: [source, destination | _]} do
      %{id: parcel_id} =
        parcel =
        create_parcel(%{
          description: "Chair",
          source_id: source.id,
          destination_id: destination.id
        })

      %{id: source_id, name: source_name} = source
      %{id: destination_id, name: destination_name} = destination

      conn = get(conn, ~p"/api/parcels/#{parcel}")

      assert %{
               "id" => ^parcel_id,
               "description" => "Chair",
               "is_delivered" => false,
               "is_shipped" => false,
               "movements" => [
                 %{
                   "location" => %{"id" => ^source_id, "name" => ^source_name},
                   "transfered_at" => _timestamp
                 }
               ],
               "source" => %{"id" => ^source_id, "name" => ^source_name},
               "destination" => %{"id" => ^destination_id, "name" => ^destination_name}
             } = json_response(conn, 200)["data"]
    end

    test "returns correct response when parcel is shipped",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: parcel_id} =
        parcel =
        create_parcel(%{source_id: location_a.id, destination_id: location_c.id})

      {_parcel, _movements} = transfer_parcel(parcel, location_b.id)
      conn = get(conn, ~p"/api/parcels/#{parcel}")

      assert %{
               "id" => ^parcel_id,
               "is_delivered" => false,
               "is_shipped" => true
             } =
               json_response(conn, 200)["data"]
    end

    test "returns correct response when parcel is delivered",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: parcel_id} =
        parcel =
        create_parcel(%{source_id: location_a.id, destination_id: location_c.id})

      {_parcel, _movements} = transfer_parcel(parcel, location_b.id)
      {_parcel, _movements} = transfer_parcel(parcel, location_c.id)
      conn = get(conn, ~p"/api/parcels/#{parcel}")

      assert %{
               "id" => ^parcel_id,
               "is_delivered" => true,
               "is_shipped" => true
             } =
               json_response(conn, 200)["data"]
    end

    test "returns parcel with a single movement when no transfers are made",
         %{conn: conn, locations: [location_a, location_b | _]} do
      %{id: parcel_id} =
        parcel =
        create_parcel(%{source_id: location_a.id, destination_id: location_b.id})

      conn = get(conn, ~p"/api/parcels/#{parcel}")

      assert %{
               "id" => ^parcel_id,
               "is_delivered" => false,
               "is_shipped" => false,
               "movements" => [_movement]
             } =
               json_response(conn, 200)["data"]
    end

    test "returns 404 when parcel does not exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, ~p"/api/parcels/#{0}")
      end
    end

    test "return 400 when the parcel ID is not an integer", %{conn: conn} do
      assert_error_sent 400, fn ->
        get(conn, ~p"/api/parcels/foo")
      end
    end

    test "renders a parcel with associated movements ordered", %{conn: conn} do
      %{id: location_a_id} = location_a = create_location(%{name: "Location A"})
      %{id: location_b_id} = location_b = create_location(%{name: "Location B"})
      %{id: location_c_id} = location_c = create_location(%{name: "Location C"})

      %{id: parcel_id} =
        parcel =
        create_parcel(%{source_id: location_a.id, destination_id: location_c.id})

      {_parcel, _movements} = transfer_parcel(parcel, location_b.id)
      {_parcel, _movements} = transfer_parcel(parcel, location_c.id)

      conn = get(conn, ~p"/api/parcels/#{parcel}")

      assert %{
               "id" => ^parcel_id,
               "is_delivered" => true,
               "is_shipped" => true,
               "movements" => [
                 %{"location" => %{"id" => ^location_a_id}},
                 %{"location" => %{"id" => ^location_b_id}},
                 %{"location" => %{"id" => ^location_c_id}}
               ]
             } =
               json_response(conn, 200)["data"]
    end

    test "renders a parcel with cyclic paths",
         %{conn: conn, locations: [location_a, location_b, location_c, location_d | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c
      %{id: location_d_id} = location_d

      %{id: parcel_id} =
        parcel =
        create_parcel(%{source_id: location_a.id, destination_id: location_d.id})

      {_parcel, _movements} = transfer_parcel(parcel, location_b.id)
      {_parcel, _movements} = transfer_parcel(parcel, location_c.id)
      {_parcel, _movements} = transfer_parcel(parcel, location_b.id)
      {_parcel, _movements} = transfer_parcel(parcel, location_c.id)
      {_parcel, _movements} = transfer_parcel(parcel, location_d.id)

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
               "is_shipped" => false,
               "source" => %{"id" => ^source_id},
               "destination" => %{"id" => ^destination_id},
               "movements" => [
                 %{"location" => %{"id" => ^source_id, "name" => "Campinas - SP"}}
               ]
             } = json_response(conn, 201)["data"]
    end

    test "ensures parcels with identical source and destination IDs but different descriptions are created as separate entities",
         %{conn: conn, locations: [source, destination | _]} do
      parcel_params = %{source_id: source.id, destination_id: destination.id}

      conn = post(conn, ~p"/api/parcels", parcel: Map.put(parcel_params, :description, "TV"))
      assert parcel_a = json_response(conn, 201)["data"]
      assert parcel_a["description"] == "TV"

      conn = post(conn, ~p"/api/parcels", parcel: Map.put(parcel_params, :description, "Piano"))
      assert parcel_b = json_response(conn, 201)["data"]
      assert parcel_b["description"] == "Piano"

      assert parcel_a["id"] != parcel_b["id"]
    end

    test "renders errors when 'source' and 'destination' locations are the same",
         %{conn: conn} do
      %{id: location_id} = create_location()

      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: location_id, destination_id: location_id, description: "Bookcase"}
        )

      errors = json_response(conn, 422)["errors"]
      assert "must be not equal to source_id's change value" in errors["destination_id"]
    end

    test "renders errors when 'source' location doesn't exist",
         %{conn: conn, locations: [destination | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: 0, destination_id: destination.id, description: "Jukebox"}
        )

      errors = json_response(conn, 422)["errors"]
      assert "does not exist" in errors["source_id"]
    end

    test "renders errors when 'destination' location doesn't exist",
         %{conn: conn, locations: [source | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{destination_id: 0, source_id: source.id, description: "Gramophone"}
        )

      errors = json_response(conn, 422)["errors"]
      assert "does not exist" in errors["destination_id"]
    end

    test "renders errors when 'source' is missing",
         %{conn: conn, locations: [destination | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{destination_id: destination.id, description: "Coffee table"}
        )

      errors = json_response(conn, 422)["errors"]
      assert "can't be blank" in errors["source_id"]
    end

    test "renders errors when 'destination' is missing",
         %{conn: conn, locations: [source | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: source.id, description: "Pinball machine"}
        )

      errors = json_response(conn, 422)["errors"]
      assert "can't be blank" in errors["destination_id"]
    end

    test "renders errors when 'description' is missing",
         %{conn: conn, locations: [source, destination | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: source.id, destination_id: destination.id}
        )

      errors = json_response(conn, 422)["errors"]
      assert "can't be blank" in errors["description"]
    end

    test "renders errors when 'description' is empty",
         %{conn: conn, locations: [source, destination | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{source_id: source.id, destination_id: destination.id, description: ""}
        )

      errors = json_response(conn, 422)["errors"]
      assert "can't be blank" in errors["description"]
    end

    test "renders errors when 'description' is too short",
         %{conn: conn, locations: [source, destination | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{
            source_id: source.id,
            destination_id: destination.id,
            description: "x"
          }
        )

      errors = json_response(conn, 422)["errors"]
      assert "should be at least 2 character(s)" in errors["description"]
    end

    test "renders errors when 'description' is too long",
         %{conn: conn, locations: [source, destination | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{
            source_id: source.id,
            destination_id: destination.id,
            description: String.duplicate("x", 1000)
          }
        )

      errors = json_response(conn, 422)["errors"]
      assert "should be at most 128 character(s)" in errors["description"]
    end

    test "renders errors when 'description' is invalid",
         %{conn: conn, locations: [source, destination | _]} do
      conn =
        post(conn, ~p"/api/parcels",
          parcel: %{
            source_id: source.id,
            destination_id: destination.id,
            description: 123
          }
        )

      errors = json_response(conn, 422)["errors"]
      assert "is invalid" in errors["description"]
    end

    test "renders errors when no JSON body is sent", %{conn: conn} do
      assert_error_sent 400, fn ->
        post(conn, ~p"/api/parcels")
      end
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/parcels", parcel: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "transfer" do
    setup [:locations]

    test "successfully transfers parcel to a valid location",
         %{conn: conn, locations: [source, destination | _]} do
      %{id: source_id} = source
      %{id: destination_id} = destination

      %{id: parcel_id, is_delivered: false} =
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

    test "adds new movement for each transfer",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c

      parcel =
        create_parcel(%{
          description: "Stool",
          source_id: location_a_id,
          destination_id: location_c_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})

      assert [
               %{"location" => %{"id" => ^location_a_id}},
               %{"location" => %{"id" => ^location_b_id}}
             ] = json_response(conn, 200)["data"]["movements"]

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_c_id})

      assert [
               %{"location" => %{"id" => ^location_a_id}},
               %{"location" => %{"id" => ^location_b_id}},
               %{"location" => %{"id" => ^location_c_id}}
             ] = json_response(conn, 200)["data"]["movements"]
    end

    test "prevents transfer when parcel has already been delivered",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c

      parcel =
        create_parcel(%{
          description: "Radio receiver",
          source_id: location_a_id,
          destination_id: location_b_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})
      body = json_response(conn, 200)["data"]
      assert body["is_delivered"] == true

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_c_id})
      errors = json_response(conn, 422)["errors"]
      assert "has already been delivered" in errors["parcel_id"]
    end

    test "ensures 'is_delivered' remains 'false' for intermediate transfers",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c

      parcel =
        create_parcel(%{
          description: "Carpet",
          source_id: location_a_id,
          destination_id: location_c_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})
      body = json_response(conn, 200)["data"]
      assert body["is_delivered"] == false

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_c_id})
      json_response(conn, 200)
    end

    test "prevents transfer when the request body contains invalid JSON",
         %{conn: conn, locations: [location_a, location_b | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b

      parcel =
        create_parcel(%{
          description: "Dishwasher",
          source_id: location_a_id,
          destination_id: location_b_id
        })

      assert_error_sent 400, fn ->
        post(conn, ~p"/api/parcels/#{parcel}/transfer", %{foo: "bar"})
      end
    end

    test "prevents transfer when 'to_location_id' is a non-integer value",
         %{conn: conn, locations: [location_a, location_b | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b

      parcel =
        create_parcel(%{
          description: "Vacuum cleaner",
          source_id: location_a_id,
          destination_id: location_b_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: "invalid"})
      assert "is invalid" in json_response(conn, 422)["errors"]["to_location_id"]
    end

    test "allows cyclic transfers",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c

      parcel =
        create_parcel(%{
          description: "Workbench",
          source_id: location_a_id,
          destination_id: location_c_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})
      json_response(conn, 200)

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_a_id})
      json_response(conn, 200)

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})
      json_response(conn, 200)

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_a_id})
      json_response(conn, 200)

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})
      json_response(conn, 200)

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_c_id})
      body = json_response(conn, 200)["data"]

      assert [
               ^location_a_id,
               ^location_b_id,
               ^location_a_id,
               ^location_b_id,
               ^location_a_id,
               ^location_b_id,
               ^location_c_id
             ] = for(movement <- body["movements"], do: movement["location"]["id"])
    end

    test "allows concurrent transfers with identical source and destination locations",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c

      parcel_x =
        create_parcel(%{
          description: "Chopsticks",
          source_id: location_a_id,
          destination_id: location_c_id
        })

      parcel_y =
        create_parcel(%{
          description: "Spoon",
          source_id: location_a_id,
          destination_id: location_c_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel_x}/transfer", %{location_id: location_b_id})
      json_response(conn, 200)

      conn = post(conn, ~p"/api/parcels/#{parcel_y}/transfer", %{location_id: location_b_id})
      json_response(conn, 200)

      conn = post(conn, ~p"/api/parcels/#{parcel_x}/transfer", %{location_id: location_c_id})
      body_x = json_response(conn, 200)["data"]

      conn = post(conn, ~p"/api/parcels/#{parcel_y}/transfer", %{location_id: location_c_id})
      body_y = json_response(conn, 200)["data"]

      assert length(body_x["movements"]) == 3
      assert length(body_y["movements"]) == 3

      # It would be nice to `assert body_x["movements"] !== body_y["movements"]` here,
      # but we can't rely on `transfered_at` values because the transfers can happen on the exact
      # same time, resulting on false-positives. I've also considered adding a `Process.sleep/1`,
      # but it would slow down the tests 🤨
    end

    test "ensures 'is_shipped' is updated to 'true' when the first transfer occurs",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c

      %{is_shipped: false} =
        parcel =
        create_parcel(%{
          description: "Air fryer",
          source_id: location_a_id,
          destination_id: location_c_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})
      body = json_response(conn, 200)["data"]
      assert body["is_shipped"] == true
    end

    test "prevents transfer to the same location as the current one",
         %{conn: conn, locations: [location_a, location_b, location_c | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b
      %{id: location_c_id} = location_c

      parcel =
        create_parcel(%{
          description: "Closet",
          source_id: location_a_id,
          destination_id: location_c_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})
      json_response(conn, 200)["data"]

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_b_id})
      errors = json_response(conn, 422)["errors"]
      assert "same location as the current one" in errors["to_location_id"]
    end

    test "prevents transfer when 'to_location_id' does not exist",
         %{conn: conn, locations: [location_a, location_b | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b

      parcel =
        create_parcel(%{
          description: "Bed",
          source_id: location_a_id,
          destination_id: location_b_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: 0})
      errors = json_response(conn, 422)["errors"]
      assert "does not exist" in errors["to_location_id"]
    end

    test "fails when the transfer location is the same as the current location",
         %{conn: conn, locations: [location_a, location_b | _]} do
      %{id: location_a_id} = location_a
      %{id: location_b_id} = location_b

      parcel =
        create_parcel(%{
          description: "Fork",
          source_id: location_a_id,
          destination_id: location_b_id
        })

      conn = post(conn, ~p"/api/parcels/#{parcel}/transfer", %{location_id: location_a_id})
      errors = json_response(conn, 422)["errors"]
      assert "same location as the current one" in errors["to_location_id"]
    end

    test "fails when the parcel ID does not exist",
         %{conn: conn, locations: [location | _]} do
      assert_error_sent 404, fn ->
        post(conn, ~p"/api/parcels/#{0}/transfer", %{location_id: location.id})
      end
    end
  end

  defp create_parcel(attrs) do
    {:ok, parcel} =
      attrs
      |> Enum.into(%{
        description: "my parcel"
      })
      |> Logistics.create_parcel()

    parcel
  end

  defp transfer_parcel(parcel, to_location_id)
       when is_struct(parcel) and is_integer(to_location_id) do
    {:ok, parcel, movements} = Logistics.transfer_parcel(parcel, to_location_id)

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
