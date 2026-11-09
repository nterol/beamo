defmodule BeamoWeb.MeControllerTest do
  use BeamoWeb.ConnCase, async: true

  setup %{conn: conn} do
    {conn, user} = authed(conn)
    %{conn: conn, user: user}
  end

  test "updates settings", %{conn: conn} do
    conn =
      patch(conn, ~p"/api/me", %{
        name: "  Tom ",
        radius_km: 25,
        quiet_start: "23:00:00",
        quiet_end: "08:00:00",
        timezone: "America/New_York"
      })

    assert %{
             "name" => "Tom",
             "radius_km" => 25,
             "quiet_start" => "23:00:00",
             "quiet_end" => "08:00:00",
             "timezone" => "America/New_York"
           } = json_response(conn, 200)
  end

  test "a nil radius means no radius", %{conn: conn} do
    assert %{"radius_km" => nil} = json_response(patch(conn, ~p"/api/me", %{radius_km: nil}), 200)
  end

  test "rejects an unknown timezone and half-set quiet hours", %{conn: conn} do
    conn = patch(conn, ~p"/api/me", %{timezone: "Mars/Olympus", quiet_start: "23:00:00"})
    assert %{"details" => details} = json_response(conn, 422)
    assert Map.keys(details) |> Enum.sort() == ["quiet_start", "timezone"]
  end

  test "stores a coarsened location", %{conn: conn, user: user} do
    assert response(put(conn, ~p"/api/me/location", %{lat: 48.856614, lng: 2.3522219}), 204)
    user = Beamo.Accounts.get_user(user.id)
    assert {user.lat, user.lng} == {48.855, 2.35}
    assert user.located_at
  end

  test "rejects a malformed location", %{conn: conn} do
    assert json_response(put(conn, ~p"/api/me/location", %{lat: "here"}), 422)
    assert json_response(put(conn, ~p"/api/me/location", %{lat: 91, lng: 0}), 422)
  end

  test "deletes the account", %{conn: conn, user: user} do
    assert response(delete(conn, ~p"/api/me"), 204)
    refute Beamo.Accounts.get_user(user.id)
    assert json_response(get(conn, ~p"/api/me"), 401)
  end
end
