defmodule Beamo.Social.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "friendships" do
    field :status, Ecto.Enum, values: [:pending, :accepted], default: :pending
    belongs_to :requester, Beamo.Accounts.User
    belongs_to :addressee, Beamo.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def request_changeset(requester_id, addressee_id) do
    %__MODULE__{requester_id: requester_id, addressee_id: addressee_id}
    |> change()
    |> unique_constraint([:requester_id, :addressee_id], name: :friendships_pair_index)
    |> foreign_key_constraint(:addressee_id)
    |> check_constraint(:addressee_id, name: :not_self)
  end
end
