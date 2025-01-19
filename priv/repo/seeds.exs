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

alias Jaiminho.Repo.Migration.Seeds
alias Jaiminho.Logistics.Location

Enum.each(1..1000, fn x ->
  Jaiminho.Repo.insert!(%Location{name: "Location #{Seeds.to_bb26(x)}"})
end)
