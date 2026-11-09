defmodule Beamo.Repo.Migrations.CreateCommunities do
  use Ecto.Migration

  def change do
    create table(:communities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create table(:community_members, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :community_id, references(:communities, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :invited_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :status, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:community_members, [:community_id, :user_id])
    create index(:community_members, [:user_id, :status])
  end
end
