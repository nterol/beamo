defmodule Beamo.Repo.Migrations.CreateBeams do
  use Ecto.Migration

  def change do
    create table(:beams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :parent_id, references(:beams, type: :binary_id, on_delete: :nilify_all)
      add :category, :string, null: false
      add :note, :string
      add :lat, :float, null: false
      add :lng, :float, null: false
      add :reach_km, :integer
      add :expires_at, :utc_datetime, null: false
      add :ended_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:beams, [:user_id],
             where: "ended_at IS NULL",
             name: :beams_one_open_per_user
           )

    create index(:beams, [:user_id, :inserted_at])
    create index(:beams, [:parent_id])

    create table(:beam_recipients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :beam_id, references(:beams, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :notified_at, :utc_datetime
      add :seen_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:beam_recipients, [:beam_id, :user_id])
    create index(:beam_recipients, [:user_id, :notified_at])

    create table(:mutes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :muted_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:mutes, [:user_id, :muted_id])
  end
end
