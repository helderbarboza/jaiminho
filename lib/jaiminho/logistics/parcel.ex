defmodule Jaiminho.Logistics.Parcel do
  alias Jaiminho.Logistics.Location
  use Ecto.Schema
  import Ecto.Changeset

  schema "parcels" do
    field :description, :string
    field :is_delivered, :boolean, default: false
    belongs_to :source, Location
    belongs_to :destination, Location

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(parcel, attrs) do
    parcel
    |> cast(attrs, [:description, :source_id, :destination_id])
    |> validate_required([:description, :source_id, :destination_id])
    |> foreign_key_constraint(:source_id)
    |> foreign_key_constraint(:destination_id)
  end
end
