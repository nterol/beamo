defmodule Beamo.Beams.Beam do
  use Ecto.Schema
  import Ecto.Changeset

  @categories [:movie, :drink, :coffee, :outdoor, :sport, :other]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "beams" do
    field :category, Ecto.Enum, values: @categories
    field :note, :string
    field :lat, :float
    field :lng, :float
    field :reach_km, :integer
    field :expires_at, :utc_datetime
    field :ended_at, :utc_datetime
    belongs_to :user, Beamo.Accounts.User
    belongs_to :parent, __MODULE__
    has_many :replies, __MODULE__, foreign_key: :parent_id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def categories, do: @categories

  def create_changeset(beam, attrs) do
    beam
    |> cast(attrs, [:category, :note])
    |> validate_required([:category])
    |> update_change(:note, &String.trim/1)
    |> validate_length(:note, max: 140)
    |> unique_constraint(:user_id, name: :beams_one_open_per_user, message: "already_active")
  end

  def active?(beam, now \\ DateTime.utc_now())

  def active?(%__MODULE__{ended_at: nil, expires_at: expires_at}, now),
    do: DateTime.after?(expires_at, now)

  def active?(_beam, _now), do: false
end
