# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Jaiminho.Repo.insert!(%Jaiminho.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

defmodule Jaiminho.Repo.Migration.Seeds do
  def to_bb26(0), do: ""

  def to_bb26(number) when number > 0 do
    remainder = rem(number, 26)
    index = if remainder == 0, do: 26, else: remainder
    quotient = div(number - 1, 26)

    to_bb26(quotient) <> <<index + ?A - 1>>
  end
end

alias Jaiminho.Logistics.Movement
alias Jaiminho.Logistics.Parcel
alias Jaiminho.Repo.Migration.Seeds
alias Jaiminho.Logistics.Location
alias Jaiminho.Repo
require Logger

Repo.transaction(fn ->
  Logger.info("Creating locations...")

  Enum.each(1..20, fn x ->
    Repo.insert!(%Location{name: "Location #{Seeds.to_bb26(x)}"})
  end)

  # Inserting a idle parcel, with no movements
  Logger.info("Creating idle parcel...")

  %Parcel{id: parcel_id} =
    Repo.insert!(%Parcel{
      description: "a idle parcel with source 1 and destination 10",
      source_id: 1,
      destination_id: 10,
      is_delivered: false
    })

  Repo.insert!(%Movement{parcel_id: parcel_id, to_location_id: 1, parent_id: nil})

  # Inserting a shipped parcel, with no movements
  Logger.info("Creating shipped parcel...")

  %Parcel{id: parcel_id} =
    Repo.insert!(%Parcel{
      description: "a shipped parcel with source 7 and destination 9",
      source_id: 7,
      destination_id: 9,
      is_delivered: false
    })

  %Movement{id: parent_id} =
    Repo.insert!(%Movement{parcel_id: parcel_id, to_location_id: 7, parent_id: nil})

  %Movement{id: _parent_id} =
    Repo.insert!(%Movement{parcel_id: parcel_id, to_location_id: 8, parent_id: parent_id})

  # Inserting a delivered parcel, along with its movements
  Logger.info("Creating delivered parcel...")

  %Parcel{id: parcel_id} =
    Repo.insert!(%Parcel{
      description: "a delivered parcel with source 3 and destination 6",
      source_id: 3,
      destination_id: 6,
      is_delivered: true
    })

  %Movement{id: parent_id} =
    Repo.insert!(%Movement{parcel_id: parcel_id, to_location_id: 3, parent_id: nil})

  %Movement{id: parent_id} =
    Repo.insert!(%Movement{parcel_id: parcel_id, to_location_id: 4, parent_id: parent_id})

  %Movement{id: parent_id} =
    Repo.insert!(%Movement{parcel_id: parcel_id, to_location_id: 5, parent_id: parent_id})

  %Movement{id: _parent_id} =
    Repo.insert!(%Movement{parcel_id: parcel_id, to_location_id: 6, parent_id: parent_id})
end)
