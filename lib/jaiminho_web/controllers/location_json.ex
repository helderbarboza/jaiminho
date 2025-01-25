defmodule JaiminhoWeb.LocationJSON do
  alias Jaiminho.Logistics.Location
  alias Jaiminho.Logistics.Parcel

  @doc """
  Renders a single location.
  """
  def show(%{location: location, parcels: parcels}) do
    %{data: data(location, parcels)}
  end

  defp data(%Location{} = location, parcels) do
    %{
      id: location.id,
      name: location.name,
      parcels: Enum.map(parcels, &parcel_data/1)
    }
  end

  defp parcel_data(%Parcel{} = parcel) do
    %{
      id: parcel.id,
      description: parcel.description,
      is_delivered: parcel.is_delivered,
      is_shipped: parcel.is_shipped,
      source: format_location(parcel.source),
      destination: format_location(parcel.destination)
    }
  end

  defp format_location(%Location{} = location) do
    %{
      id: location.id,
      name: location.name
    }
  end
end
