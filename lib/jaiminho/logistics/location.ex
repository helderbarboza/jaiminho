defmodule Jaiminho.Logistics.Location do
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "locations" do
    field :name, :string, null: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
