defmodule Jaiminho.Logistics do
  @moduledoc """
  The Logistics context.
  """

  import Ecto.Query, warn: false
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
  def get_parcel!(id), do: Repo.get!(Parcel, id)

  @doc """
  Creates a parcel.

  ## Examples

      iex> create_parcel(%{field: value})
      {:ok, %Parcel{}}

      iex> create_parcel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_parcel(attrs \\ %{}) do
    %Parcel{}
    |> Parcel.changeset(attrs)
    |> Repo.insert()
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
