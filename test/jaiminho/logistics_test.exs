defmodule Jaiminho.LogisticsTest do
  use Jaiminho.DataCase

  alias Jaiminho.Logistics
  alias Jaiminho.Logistics.Parcel

  describe "locations" do
    test "get_location!/1 returns the location with given id" do
      location = create_location()

      assert Logistics.get_location!(location.id) == location
    end

    test "list_parcels_at_location/1 returns parcels currently at the location" do
      location_a = create_location()
      location_b = create_location()
      location_c = create_location()
      location_d = create_location()
      parcel_a = create_parcel(%{source_id: location_a.id, destination_id: location_b.id})
      parcel_b = create_parcel(%{source_id: location_b.id, destination_id: location_c.id})
      parcel_d1 = create_parcel(%{source_id: location_d.id, destination_id: location_a.id})
      parcel_d2 = create_parcel(%{source_id: location_d.id, destination_id: location_b.id})

      assert [^parcel_a] = Logistics.list_parcels_at_location(location_a.id)
      assert [^parcel_b] = Logistics.list_parcels_at_location(location_b.id)
      assert [] = Logistics.list_parcels_at_location(location_c.id)
      assert [^parcel_d1, ^parcel_d2] = Logistics.list_parcels_at_location(location_d.id)
    end
  end

  describe "parcels" do
    setup [:locations]

    @invalid_attrs %{description: nil}

    test "get_parcel_and_locations!/1 returns the parcel with given id", %{
      locations: [location_a, location_b | _]
    } do
      parcel =
        create_parcel(%{
          description: "Spatula",
          source_id: location_a.id,
          destination_id: location_b.id
        })

      assert Logistics.get_parcel_and_locations!(parcel.id) == parcel
    end

    test "create_parcel/1 with valid data creates a parcel", %{
      locations: [location_a, location_b | _]
    } do
      attrs = %{
        description: "Paper Towels",
        source_id: location_a.id,
        destination_id: location_b.id
      }

      assert {:ok, %Parcel{} = parcel} = Logistics.create_parcel(attrs)
      assert parcel.description == "Paper Towels"
      assert parcel.is_delivered == false
    end

    test "create_parcel/1 with destination equals to source returns changeset error", %{
      locations: locations
    } do
      [location | _] = locations

      attrs = %{
        description: "Illegal parcel",
        source_id: location.id,
        destination_id: location.id
      }

      assert {:error, %Ecto.Changeset{errors: [destination_id: _]}} =
               Logistics.create_parcel(attrs)
    end

    test "create_parcel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Logistics.create_parcel(@invalid_attrs)
    end

    test "transfer_parcel/2 with valid data transfers a parcel"

    test "transfer_parcel/2 with to_location equals to the current location returns changeset error"

    test "transfer_parcel/2 on a parcel marked as delivered returns changeset error"

    test "change_parcel/1 returns a parcel changeset" do
      assert %Ecto.Changeset{} = Logistics.change_parcel(%Parcel{}, %{})
    end
  end

  defp create_location(attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{name: "My location"})
      |> Logistics.create_location()

    location
  end

  defp create_parcel(attrs) do
    {:ok, parcel} =
      attrs
      |> Enum.into(%{
        description: "My parcel"
      })
      |> Logistics.create_parcel()

    parcel
  end

  defp locations(_context) do
    [
      locations: [
        create_location(%{name: "Location A"}),
        create_location(%{name: "Location B"}),
        create_location(%{name: "Location C"})
      ]
    ]
  end
end
