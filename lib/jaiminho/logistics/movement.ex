defmodule Jaiminho.Logistics.Movement do
  @moduledoc """
  A graph node tracking parcel location changes.
  """

  use TypedEctoSchema
  import Ecto.Changeset
  alias Jaiminho.Logistics.Location
  alias Jaiminho.Logistics.Parcel
  alias Jaiminho.Repo

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
  @spec descendant_node_changeset(t(), map(), pos_integer()) :: Ecto.Changeset.t()
  def descendant_node_changeset(movement, attrs, current_location_id) do
    movement
    |> base_changeset(attrs)
    |> cast(attrs, [:parent_id])
    |> validate_required([:parent_id])
    |> foreign_key_constraint(:parent_id)
    |> validate_against_current_location(current_location_id)
    |> validate_delivered_status()
  end

  defp base_changeset(movement, attrs) do
    movement
    |> cast(attrs, [:parcel_id, :to_location_id])
    |> validate_required([:parcel_id, :to_location_id])
    |> foreign_key_constraint(:parcel_id)
    |> foreign_key_constraint(:to_location_id)
  end

  defp validate_against_current_location(changeset, current_location_id) do
    validate_change(changeset, :to_location_id, fn
      :to_location_id, ^current_location_id ->
        [to_location_id: {"same location as the current one", []}]

      :to_location_id, _to_location_id ->
        []
    end)
  end

  defp validate_delivered_status(changeset) do
    %Parcel{is_delivered: is_delivered} =
      changeset
      |> apply_changes()
      |> Ecto.assoc(:parcel)
      |> Repo.one!()

    if is_delivered do
      add_error(changeset, :parcel_id, "has already been delivered")
    else
      changeset
    end
  end
end
