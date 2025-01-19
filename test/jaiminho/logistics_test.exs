defmodule Jaiminho.LogisticsTest do
  use Jaiminho.DataCase

  alias Jaiminho.Logistics

  describe "locations" do
    test "get_location!/1 returns the location with given id" do
      location = create_location()

      assert Logistics.get_location!(location.id) == location
    end
  end

  describe "parcels" do
    alias Jaiminho.Logistics.Parcel

    @invalid_attrs %{description: nil, is_delivered: nil}

    test "get_parcel!/1 returns the parcel with given id" do
      parcel = create_parcel()
      assert Logistics.get_parcel!(parcel.id) == parcel
    end

    test "create_parcel/1 with valid data creates a parcel" do
      attrs = %{description: "a valid parcel", is_delivered: true}
      assert {:ok, %Parcel{} = parcel} = Logistics.create_parcel(attrs)
      assert parcel.description == "a valid parcel"
      assert parcel.is_delivered == true
    end

    test "create_parcel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Logistics.create_parcel(@invalid_attrs)
    end

    test "transfer_parcel/1 with valid data transfers a parcel"

    test "transfer_parcel/1 with to_location equals to the current location returns changeset error"

    test "transfer_parcel/1 on a parcel marked as delivered returns changeset error"

    test "change_parcel/1 returns a parcel changeset" do
      parcel = create_parcel()
      assert %Ecto.Changeset{} = Logistics.change_parcel(parcel)
    end
  end

  defp create_location() do
    {:ok, location} = Logistics.create_location(%{name: "location"})
    location
  end

  defp create_parcel(attrs \\ %{}) do
    {:ok, parcel} =
      attrs
      |> Enum.into(%{
        description: "my parcel",
        is_delivered: false
      })
      |> Logistics.create_parcel()

    parcel
  end
end
