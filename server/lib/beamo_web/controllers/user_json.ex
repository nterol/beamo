defmodule BeamoWeb.UserJSON do
  alias Beamo.Accounts.User

  def me(%User{} = u) do
    %{
      id: u.id,
      phone: u.phone,
      name: u.name,
      radius_mode: u.radius_mode,
      radius_km: u.radius_km,
      quiet_start: u.quiet_start,
      quiet_end: u.quiet_end,
      timezone: u.timezone,
      located_at: u.located_at
    }
  end

  def public(%User{} = u), do: %{id: u.id, name: u.name}
end
