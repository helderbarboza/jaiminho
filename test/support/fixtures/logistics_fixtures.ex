defmodule Jaiminho.LogisticsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jaiminho.Logistics` context.
  """

  @doc """
  Generate a location.
  """
  def location_fixture(attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Jaiminho.Logistics.create_location()

    location
  end
end
