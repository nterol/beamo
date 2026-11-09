defmodule Beamo.Repo.Migrations.CreateCoreTables do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :phone, :string, null: false
      add :phone_hash, :string, null: false
      add :name, :string
      add :radius_km, :integer, default: 10
      add :quiet_start, :time
      add :quiet_end, :time
      add :timezone, :string, null: false, default: "Europe/Paris"
      add :lat, :float
      add :lng, :float
      add :located_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:phone])
    create unique_index(:users, [:phone_hash])

    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token_hash, :binary, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:sessions, [:token_hash])
    create index(:sessions, [:user_id])

    create table(:friendships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :requester_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :addressee_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create unique_index(
             :friendships,
             ["LEAST(requester_id, addressee_id)", "GREATEST(requester_id, addressee_id)"],
             name: :friendships_pair_index
           )

    create index(:friendships, [:addressee_id])
    create constraint(:friendships, :not_self, check: "requester_id <> addressee_id")

    create table(:blocks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :blocker_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :blocked_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:blocks, [:blocker_id, :blocked_id])
    create index(:blocks, [:blocked_id])

    create table(:push_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :platform, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:push_tokens, [:token])
    create index(:push_tokens, [:user_id])
  end
end
