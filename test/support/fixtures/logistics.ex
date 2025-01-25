defmodule Jaiminho.LogisticsFixtures do
  @moduledoc false

  alias Jaiminho.Logistics

  def create_parcel(attrs) do
    {:ok, parcel} =
      attrs
      |> Enum.into(%{
        description: "My parcel"
      })
      |> Logistics.create_parcel()

    parcel
  end

  def transfer_parcel(parcel, to_location_id)
      when is_struct(parcel) and is_integer(to_location_id) do
    {:ok, parcel, movements} = Logistics.transfer_parcel(parcel, to_location_id)

    {parcel, movements}
  end

  def create_location(attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{name: "My location"})
      |> Logistics.create_location()

    location
  end

  def locations(_context) do
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
