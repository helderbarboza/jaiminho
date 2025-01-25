defmodule JaiminhoWeb.ParcelJSON do
  alias Jaiminho.Logistics.Location
  alias Jaiminho.Logistics.Movement
  alias Jaiminho.Logistics.Parcel

  @doc """
  Renders a single parcel.
  """
  def show(%{parcel: parcel, movements: movements}) do
    %{data: data(parcel, movements)}
  end

  defp data(%Parcel{} = parcel, movements) do
    %{
      id: parcel.id,
      description: parcel.description,
      is_delivered: parcel.is_delivered,
      is_shipped: parcel.is_shipped,
      source: location_data(parcel.source),
      destination: location_data(parcel.destination),
      movements: Enum.map(movements, &movement_data/1)
    }
  end

  defp movement_data(%Movement{} = movement) do
    %{
      transfered_at: movement.inserted_at,
      location: %{id: movement.to_location.id, name: movement.to_location.name}
    }
  end

  defp location_data(%Location{} = location) do
    %{
      id: location.id,
      name: location.name
    }
  end
end
