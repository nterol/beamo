defmodule Beamo.Social.Mute do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "mutes" do
    belongs_to :user, Beamo.Accounts.User
    belongs_to :muted, Beamo.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
