defmodule Beamo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :phone, :string
    field :phone_hash, :string
    field :name, :string
    field :radius_km, :integer, default: 10
    field :quiet_start, :time
    field :quiet_end, :time
    field :timezone, :string, default: "Europe/Paris"
    field :lat, :float
    field :lng, :float
    field :located_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @e164 ~r/^\+[1-9]\d{7,14}$/

  def e164?(phone) when is_binary(phone), do: Regex.match?(@e164, phone)
  def e164?(_), do: false

  def hash_phone(phone), do: :crypto.hash(:sha256, phone) |> Base.encode16(case: :lower)

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:phone])
    |> validate_required([:phone])
    |> validate_format(:phone, @e164)
    |> then(&put_change(&1, :phone_hash, hash_phone(get_field(&1, :phone) || "")))
    |> unique_constraint(:phone)
  end

  def settings_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :radius_km, :quiet_start, :quiet_end, :timezone])
    |> update_change(:name, &String.trim/1)
    |> validate_length(:name, min: 1, max: 40)
    |> validate_number(:radius_km, greater_than: 0, less_than_or_equal_to: 500)
    |> validate_required([:timezone])
    |> validate_change(:timezone, fn :timezone, tz ->
      if Tz.TimeZoneDatabase.time_zone_periods_from_wall_datetime(~N[2026-01-01 12:00:00], tz) ==
           {:error, :time_zone_not_found},
         do: [timezone: "is unknown"],
         else: []
    end)
    |> validate_quiet_hours()
  end

  @grid 200

  def location_changeset(user, %{"lat" => lat, "lng" => lng})
      when is_number(lat) and is_number(lng) do
    user
    |> change(
      lat: Float.round(round(lat * @grid) / @grid, 3),
      lng: Float.round(round(lng * @grid) / @grid, 3),
      located_at: DateTime.utc_now(:second)
    )
    |> validate_number(:lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:lng, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
  end

  def location_changeset(user, _attrs) do
    user |> change() |> add_error(:location, "lat and lng must be numbers")
  end

  defp validate_quiet_hours(changeset) do
    case {get_field(changeset, :quiet_start), get_field(changeset, :quiet_end)} do
      {nil, nil} -> changeset
      {%Time{}, %Time{}} -> changeset
      _ -> add_error(changeset, :quiet_start, "quiet_start and quiet_end go together")
    end
  end
end
