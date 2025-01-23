defmodule Jaiminho.Logistics.Movement do
  @moduledoc """
  A graph node tracking parcel location changes.
  """

  use TypedEctoSchema
  import Ecto.Changeset
  alias Jaiminho.Logistics.Location
  alias Jaiminho.Logistics.Parcel

  typed_schema "movements" do
    belongs_to :parcel, Parcel
    belongs_to :parent, __MODULE__, foreign_key: :parent_id, references: :id
    has_one :child, __MODULE__, foreign_key: :parent_id, references: :id
    belongs_to :to_location, Location

    timestamps type: :utc_datetime
  end

  @doc false
  @spec root_node_changeset(t(), map()) :: Ecto.Changeset.t()
  def root_node_changeset(movement, attrs) do
    base_changeset(movement, attrs)
  end

  @doc false
  @spec descendant_node_changeset(t(), map()) :: Ecto.Changeset.t()
  def descendant_node_changeset(movement, attrs) do
    movement
    |> base_changeset(attrs)
    |> cast(attrs, [:parent_id])
    |> validate_required([:parent_id])
    |> foreign_key_constraint(:parent_id)
  end

  defp base_changeset(movement, attrs) do
    movement
    |> cast(attrs, [:parcel_id, :to_location_id])
    |> validate_required([:parcel_id, :to_location_id])
    |> foreign_key_constraint(:parcel_id)
    |> foreign_key_constraint(:to_location_id)
  end
end
