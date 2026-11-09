defmodule Beamo.Accounts.Session do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sessions" do
    field :token_hash, :binary
    field :expires_at, :utc_datetime
    belongs_to :user, Beamo.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
