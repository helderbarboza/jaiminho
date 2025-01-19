defmodule Jaiminho.LogisticsTest do
  use Jaiminho.DataCase

  alias Jaiminho.Logistics

  describe "locations" do
    import Jaiminho.LogisticsFixtures

    test "get_location!/1 returns the location with given id" do
      location = location_fixture()
      assert Logistics.get_location!(location.id) == location
    end
  end
end
