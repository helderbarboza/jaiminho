defmodule Jaiminho.Logistics.Parcel do
  alias Jaiminho.Logistics.Location
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "parcels" do
    field :description, :string, null: false
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
    |> then(fn changeset ->
      validate_change(changeset, :destination_id, fn :destination_id, destination_id ->
        if destination_id !== get_change(changeset, :source_id) do
          []
        else
          [destination_id: {"must be not equal to %{key}'s change value", [key: :source_id]}]
        end
      end)
    end)
    |> foreign_key_constraint(:source_id)
    |> foreign_key_constraint(:destination_id)
  end
end
