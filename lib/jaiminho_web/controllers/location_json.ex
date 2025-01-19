defmodule JaiminhoWeb.LocationJSON do
  alias Jaiminho.Logistics.Location

  @doc """
  Renders a single location.
  """
  def show(%{location: location}) do
    %{data: data(location)}
  end

  defp data(%Location{} = location) do
    %{
      id: location.id,
      name: location.name
    }
  end
end
