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
      source: format_location(parcel.source),
      destination: format_location(parcel.destination),
      movements: Enum.map(movements, &format_movement/1)
    }
  end

  defp format_movement(%Movement{} = movement) do
    %{
      transfered_at: movement.inserted_at,
      location: %{id: movement.to_location.id, name: movement.to_location.name}
    }
  end

  defp format_location(%Location{} = location) do
    %{
      id: location.id,
      name: location.name
    }
  end
end
