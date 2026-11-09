defmodule Beamo.Beams.Recipient do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "beam_recipients" do
    field :notified_at, :utc_datetime
    field :seen_at, :utc_datetime
    belongs_to :beam, Beamo.Beams.Beam
    belongs_to :user, Beamo.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
