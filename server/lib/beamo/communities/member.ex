defmodule Beamo.Communities.Member do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "community_members" do
    field :status, Ecto.Enum, values: [:invited, :member]
    belongs_to :community, Beamo.Communities.Community
    belongs_to :user, Beamo.Accounts.User
    belongs_to :invited_by, Beamo.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
