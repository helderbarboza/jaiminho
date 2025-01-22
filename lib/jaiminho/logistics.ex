defmodule Jaiminho.Logistics do
  @moduledoc """
  The Logistics context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Jaiminho.Logistics.Movement
  alias Jaiminho.Repo

  alias Jaiminho.Logistics.Location

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(123)
      %Location{id: 123, name: "Somewhere over the rainbow"}

      iex> get_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(id), do: Repo.get!(Location, id)

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(%{field: value})
      {:ok, %Location{}}

      iex> create_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  alias Jaiminho.Logistics.Parcel

  @doc """
  Gets a single parcel.

  Raises `Ecto.NoResultsError` if the Parcel does not exist.

  ## Examples

      iex> get_parcel!(123)
      %Parcel{}

      iex> get_parcel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_parcel!(id) do
    Repo.get!(Parcel, id)
  end

  def get_parcel_and_locations!(id) do
    Parcel
    |> Repo.get!(id)
    |> Repo.preload([:source, :destination])
  end

  def get_movements_from_parcel(parcel_id) do
    parent_ids_query =
      Movement
      |> where([m], not is_nil(m.parent_id))
      |> select([m], m.parent_id)

    children_query =
      Movement
      |> where([m], m.id not in subquery(parent_ids_query))

    recursion_query =
      Movement
      |> join(:inner, [m], mt in "movement_tree", on: mt.parent_id == m.id)

    movement_tree_query = union_all(children_query, ^recursion_query)

    {"movement_tree", Movement}
    |> recursive_ctes(true)
    |> with_cte("movement_tree", as: ^movement_tree_query)
    |> where([m], m.parcel_id == ^parcel_id)
    |> preload(:to_location)
    |> Repo.all()
  end

  def list_parcels_at_location(location_id) do
    parent_ids_query =
      Movement
      |> where([m], not is_nil(m.parent_id))
      |> select([m], m.parent_id)

    leaf_movements_query =
      Movement
      |> where([m], m.id not in subquery(parent_ids_query))

    Parcel
    |> with_cte("leaf_movements", as: ^leaf_movements_query)
    |> join(:inner, [p], lm in {"leaf_movements", Movement}, on: p.id == lm.parcel_id)
    |> where([p, lm], lm.to_location_id == ^location_id)
    |> preload([:source, :destination])
    |> Repo.all()
  end

  @doc """
  Creates a parcel.

  ## Examples

      iex> create_parcel(%{field: value})
      {:ok, %Parcel{}}

      iex> create_parcel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_parcel(attrs \\ %{}) do
    case Repo.transaction(create_parcel_operations(attrs)) do
      {:ok, %{parcel: parcel}} -> {:ok, Repo.preload(parcel, [:source, :destination])}
      {:error, _, reason, _} -> {:error, reason}
    end
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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking parcel changes.

  ## Examples

      iex> change_parcel(parcel)
      %Ecto.Changeset{data: %Parcel{}}

  """
  def change_parcel(%Parcel{} = parcel, attrs \\ %{}) do
    Parcel.changeset(parcel, attrs)
  end
end
