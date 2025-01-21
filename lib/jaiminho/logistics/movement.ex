defmodule Jaiminho.Logistics.Movement do
  use Ecto.Schema
  import Ecto.Changeset
  alias Jaiminho.Logistics.Location
  alias Jaiminho.Logistics.Parcel

  schema "movements" do
    belongs_to :parcel, Parcel
    belongs_to :parent, __MODULE__, foreign_key: :parent_id, references: :id, define_field: true
    belongs_to :to_location, Location

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(transfer, attrs) do
    transfer
    |> cast(attrs, [])
    |> validate_required([])
  end
end
