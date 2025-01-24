defmodule Jaiminho.Repo.Migrations.AddIsShippedToParcel do
  use Ecto.Migration

  def change do
    alter table(:parcels) do
      add :is_shipped, :boolean, default: false, null: false
    end
  end
end
