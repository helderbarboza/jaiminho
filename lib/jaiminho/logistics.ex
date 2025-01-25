defmodule Jaiminho.Logistics do
  @moduledoc """
  The Logistics context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Jaiminho.Repo
  alias Jaiminho.Logistics.{Location, Movement, Parcel}

  @spec get_location!(pos_integer()) :: Location.t()
  def get_location!(id), do: Repo.get!(Location, id)

  @spec create_location() :: {:ok, Location.t()} | {:error, Ecto.Changeset.t()}
  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_parcel!(pos_integer()) :: Parcel.t()
  def get_parcel!(id) do
    Parcel
    |> Repo.get!(id)
    |> Repo.preload([:source, :destination])
  end

  @spec list_movements_of_parcel(pos_integer()) :: [Movement.t()]
  def list_movements_of_parcel(parcel_id) do
    parcel_id
    |> movements_of_parcel_query()
    |> Repo.all()
  end

  @spec list_parcels_at_location(pos_integer()) :: [Parcel.t()]
  def list_parcels_at_location(location_id) do
    parent_ids_query =
      Movement
      |> where([m], not is_nil(m.parent_id))
      |> select([m], m.parent_id)

    leaf_movements_query =
      where(Movement, [m], m.id not in subquery(parent_ids_query))

    Parcel
    |> with_cte("leaf_movements", as: ^leaf_movements_query)
    |> join(:inner, [p], lm in {"leaf_movements", Movement}, on: p.id == lm.parcel_id)
    |> where([p, lm], lm.to_location_id == ^location_id)
    |> preload([:source, :destination])
    |> Repo.all()
  end

  @spec create_parcel(map()) :: {:error, any()} | {:ok, Parcel.t()}
  def create_parcel(attrs) do
    case Repo.transaction(create_parcel_operations(attrs)) do
      {:ok, %{parcel: parcel}} -> {:ok, Repo.preload(parcel, [:source, :destination])}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  @spec transfer_parcel(Parcel.t(), Location.t()) ::
          {:error, any()} | {:ok, Parcel.t(), [Movement.t()]}
  def transfer_parcel(parcel, to_location_id) do
    case Repo.transaction(transfer_parcel_operations(parcel, to_location_id)) do
      {:ok, %{updated_parcel: parcel, movements: movements}} ->
        {:ok, Repo.preload(parcel, [:source, :destination]), movements}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  @spec change_parcel(Parcel.t(), map()) :: Ecto.Changeset.t()
  def change_parcel(%Parcel{} = parcel, attrs \\ %{}) do
    Parcel.changeset(parcel, attrs)
  end

  defp transfer_parcel_operations(parcel, to_location_id) do
    Multi.new()
    |> Multi.run(:latest_movement, fn repo, _ ->
      movement =
        parcel.id
        |> latest_movement_of_parcel_query()
        |> repo.one()

      {:ok, movement}
    end)
    |> Multi.insert(:new_movement, fn
      %{latest_movement: %{id: parent_id, to_location_id: current_location_id}} ->
        Movement.descendant_node_changeset(
          %Movement{},
          %{
            parent_id: parent_id,
            parcel_id: parcel.id,
            to_location_id: to_location_id
          },
          current_location_id
        )
    end)
    |> Multi.run(:updated_parcel, fn repo, _changes ->
      changeset =
        Ecto.Changeset.change(parcel, is_shipped: true)

      changeset =
        if parcel.destination_id === to_location_id do
          Ecto.Changeset.change(changeset, is_delivered: true)
        else
          changeset
        end

      repo.update(changeset)
    end)
    |> Multi.all(:movements, movements_of_parcel_query(parcel.id))
  end

  defp create_parcel_operations(attrs) do
    Multi.new()
    |> Multi.insert(:parcel, Parcel.changeset(%Parcel{}, attrs))
    |> Multi.insert(:movement, fn %{parcel: parcel} ->
      Movement.root_node_changeset(%Movement{}, %{
        parcel_id: parcel.id,
        to_location_id: parcel.source_id
      })
    end)
  end

  defp latest_movement_of_parcel_query(parcel_id) do
    parcel_id
    |> movements_of_parcel_query()
    |> last()
  end

  defp movements_of_parcel_query(parcel_id) do
    parent_ids_query =
      Movement
      |> where([m], not is_nil(m.parent_id))
      |> select([m], m.parent_id)

    children_query =
      where(Movement, [m], m.id not in subquery(parent_ids_query))

    recursion_query =
      join(Movement, :inner, [m], mt in "movement_tree", on: mt.parent_id == m.id)

    movement_tree_query = union_all(children_query, ^recursion_query)

    {"movement_tree", Movement}
    |> recursive_ctes(true)
    |> with_cte("movement_tree", as: ^movement_tree_query)
    |> where([m], m.parcel_id == ^parcel_id)
    |> preload(:to_location)
    |> order_by([m], asc: m.id)
  end
end
