defmodule Jaiminho.LogisticsTest do
  use Jaiminho.DataCase

  alias Jaiminho.Logistics

  describe "locations" do
    test "get_location!/1 returns the location with given id" do
      location = create_location()

      assert Logistics.get_location!(location.id) == location
    end
  end

  defp create_location() do
    {:ok, location} = Logistics.create_location(%{name: "location"})
    location
  end
end
