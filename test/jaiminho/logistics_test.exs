defmodule Jaiminho.LogisticsTest do
  use Jaiminho.DataCase

  alias Jaiminho.Logistics
  alias Jaiminho.Logistics.Parcel

  describe "locations" do
    test "get_location!/1 returns the location with given id" do
      location = create_location()

      assert Logistics.get_location!(location.id) == location
    end
  end

  describe "parcels" do
    setup [:locations]

    @invalid_attrs %{description: nil, is_delivered: nil}

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

    test "create_parcel/1 with source equals to destination returns changeset error"

    test "create_parcel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Logistics.create_parcel(@invalid_attrs)
    end

    test "get_parcels_at_location/1 returns parcels currently at the location"

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

  defp create_parcel(attrs \\ %{}) do
    {:ok, parcel} =
      attrs
      |> Enum.into(%{
        description: "My parcel",
        is_delivered: false
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
