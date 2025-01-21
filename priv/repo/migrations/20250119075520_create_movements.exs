defmodule Jaiminho.Repo.Migrations.CreateMovements do
  use Ecto.Migration

  def change do
    create table(:movements) do
      add :parcel_id, references(:parcels, on_delete: :nothing)
      add :to_location_id, references(:locations, on_delete: :nothing)
      add :parent_id, references(:movements, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:movements, [:parcel_id])
    create index(:movements, [:to_location_id])
    create index(:movements, [:parent_id])
  end
end
