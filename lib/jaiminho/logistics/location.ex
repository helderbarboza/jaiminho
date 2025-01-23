defmodule Jaiminho.Logistics.Location do
  @moduledoc """
  A physical location where parcels can be shipped or delivered.
  """
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "locations" do
    field :name, :string, null: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
