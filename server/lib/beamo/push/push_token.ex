defmodule Beamo.Push.PushToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "push_tokens" do
    field :token, :string
    field :platform, Ecto.Enum, values: [:ios, :android]
    belongs_to :user, Beamo.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(push_token, attrs) do
    push_token
    |> cast(attrs, [:token, :platform])
    |> validate_required([:token, :platform])
    |> validate_format(:token, ~r/^Expo(nent)?PushToken\[.+\]$/)
  end
end
