defmodule JaiminhoWeb.ParcelJSON do
  alias Jaiminho.Logistics.Parcel

  @doc """
  Renders a list of parcels.
  """
  def index(%{parcels: parcels}) do
    %{data: for(parcel <- parcels, do: data(parcel))}
  end

  @doc """
  Renders a single parcel.
  """
  def show(%{parcel: parcel}) do
    %{data: data(parcel)}
  end

  defp data(%Parcel{} = parcel) do
    %{
      id: parcel.id,
      description: parcel.description,
      is_delivered: parcel.is_delivered
    }
  end
end
