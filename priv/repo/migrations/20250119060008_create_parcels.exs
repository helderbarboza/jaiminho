defmodule Jaiminho.Repo.Migrations.CreateParcels do
  use Ecto.Migration

  def change do
    create table(:parcels) do
      add :description, :string
      add :is_delivered, :boolean, default: false, null: false
      add :source_id, references(:locations, on_delete: :nothing)
      add :destination_id, references(:locations, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:parcels, [:source_id])
    create index(:parcels, [:destination_id])
  end
end
