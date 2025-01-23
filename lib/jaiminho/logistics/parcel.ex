defmodule Jaiminho.Logistics.Parcel do
  @moduledoc """
  A package being transported with source/destination locations and delivery status.
  """

  use TypedEctoSchema
  import Ecto.Changeset
  alias Jaiminho.Logistics.Location

  typed_schema "parcels" do
    field :description, :string, null: false
    field :is_delivered, :boolean, default: false
    belongs_to :source, Location
    belongs_to :destination, Location

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(parcel, attrs) do
    parcel
    |> cast(attrs, [:description, :source_id, :destination_id])
    |> validate_required([:description, :source_id, :destination_id])
    |> validate_source_and_destination()
    |> foreign_key_constraint(:source_id)
    |> foreign_key_constraint(:destination_id)
  end

  defp validate_source_and_destination(changeset) do
    source_id = get_change(changeset, :source_id)

    validate_change(changeset, :destination_id, fn
      :destination_id, ^source_id ->
        [destination_id: {"must be not equal to %{key}'s change value", [key: :source_id]}]

      :destination_id, _destination_id ->
        []
    end)
  end
end
