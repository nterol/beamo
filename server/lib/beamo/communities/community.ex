defmodule Beamo.Communities.Community do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "communities" do
    field :name, :string
    belongs_to :created_by, Beamo.Accounts.User
    has_many :members, Beamo.Communities.Member

    timestamps(type: :utc_datetime)
  end

  def changeset(community, attrs) do
    community
    |> cast(attrs, [:name])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 40)
  end
end
