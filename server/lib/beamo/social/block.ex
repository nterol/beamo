defmodule Beamo.Social.Block do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "blocks" do
    belongs_to :blocker, Beamo.Accounts.User
    belongs_to :blocked, Beamo.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
