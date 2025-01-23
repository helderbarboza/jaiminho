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

  def list_movements_of_parcel(parcel_id) do
    parcel_id
    |> movements_of_parcel_query()
    |> Repo.all()
  end

  def get_latest_movement_of_parcel(parcel_id) do
    parcel_id
    |> latest_movement_of_parcel_query()
    |> Repo.one()
  end

  defp movements_of_parcel_query(parcel_id) do
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
  end

  defp latest_movement_of_parcel_query(parcel_id) do
    parcel_id
    |> movements_of_parcel_query()
    |> last()
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

  def transfer_parcel(parcel_id, to_location_id) do
    case Repo.transaction(transfer_parcel_operations(parcel_id, to_location_id)) do
      {:ok, %{updated_parcel: parcel, movements: movements}} ->
        {:ok, Repo.preload(parcel, [:source, :destination]), movements}

      {:error, _, reason, _} ->
        {:error, reason}
    end
  end

  defp transfer_parcel_operations(parcel_id, to_location_id) do
    Multi.new()
    |> Multi.run(:parcel, fn repo, _changes ->
      case repo.get(Parcel, parcel_id) do
        nil -> {:error, :not_found}
        parcel -> {:ok, parcel}
      end
    end)
    |> Multi.run(:parcel_is_delivered, fn
      _repo, %{parcel: %Parcel{is_delivered: true}} -> {:error, :already_delivered}
      _repo, _changes -> {:ok, nil}
    end)
    |> Multi.run(:to_location, fn repo, _changes ->
      case repo.get(Location, to_location_id) do
        nil -> {:error, :not_found}
        location -> {:ok, location}
      end
    end)
    |> Multi.run(:latest_movement, fn repo, _ ->
      parcel_id
      |> latest_movement_of_parcel_query()
      |> repo.one()
      |> case do
        nil -> {:error, :not_found}
        movement -> {:ok, movement}
      end
    end)
    |> Multi.run(:current_location, fn
      _repo, %{latest_movement: %{to_location_id: current_location_id}} ->
        if current_location_id !== to_location_id do
          {:ok, nil}
        else
          {:error, :to_location_and_current_location_must_be_different}
        end
    end)
    |> Multi.insert(:new_movement, fn %{latest_movement: %{id: parent_id}} ->
      Movement.descendant_node_changeset(%Movement{}, %{
        parent_id: parent_id,
        parcel_id: parcel_id,
        to_location_id: to_location_id
      })
    end)
    |> Multi.run(:updated_parcel, fn repo, %{parcel: parcel} ->
      if parcel.destination_id === to_location_id do
        parcel
        |> Ecto.Changeset.change(is_delivered: true)
        |> repo.update()
      else
        {:ok, parcel}
      end
    end)
    |> Multi.all(:movements, movements_of_parcel_query(parcel_id))
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
