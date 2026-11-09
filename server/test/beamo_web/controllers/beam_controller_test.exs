defmodule BeamoWeb.BeamControllerTest do
  use BeamoWeb.ConnCase, async: true

  alias Beamo.Beams

  setup %{conn: conn} do
    {conn, me} = authed(conn, %{"name" => "Tom"})
    {:ok, me} = Beamo.Accounts.update_location(me, %{"lat" => 48.8566, "lng" => 2.3522})
    %{conn: conn, me: me}
  end

  test "the feed stays blurred until I beam", %{conn: conn, me: me} do
    lea = located_user(:montmartre, %{"name" => "Léa"})
    max = located_user(:montmartre, %{"name" => "Max"})
    befriend(me, lea)
    befriend(me, max)
    {:ok, _} = Beams.start_beam(lea, %{"category" => "coffee"})

    assert json_response(get(conn, ~p"/api/feed"), 200) == %{
             "active" => false,
             "active_count" => 1
           }

    assert %{"beam" => %{"category" => "drink"}} =
             json_response(post(conn, ~p"/api/beams", %{category: "drink"}), 201)

    assert %{"active" => true, "friends" => [first, second]} =
             json_response(get(conn, ~p"/api/feed"), 200)

    assert %{
             "user" => %{"name" => "Léa"},
             "beam" => %{"category" => "coffee"},
             "distance_km" => 3
           } = first

    assert %{"user" => %{"name" => "Max"}, "beam" => nil, "distance_km" => nil} = second
  end

  test "beam lifecycle over the API", %{conn: conn} do
    assert %{"beam" => nil} = json_response(get(conn, ~p"/api/beams/current"), 200)

    post(conn, ~p"/api/beams", %{category: "sport", lat: 48.85, lng: 2.35})

    assert %{"error" => "already_active"} =
             json_response(post(conn, ~p"/api/beams", %{category: "sport"}), 409)

    assert %{"beam" => %{"category" => "sport"}, "reached" => 0, "seen" => 0, "replies" => []} =
             json_response(get(conn, ~p"/api/beams/current"), 200)

    assert response(delete(conn, ~p"/api/beams/current"), 204)
    assert %{"beam" => nil} = json_response(get(conn, ~p"/api/beams/current"), 200)
  end

  test "a beam needs a location", %{conn: conn} do
    {conn, _} = authed(conn)

    assert %{"error" => "location_required"} =
             json_response(post(conn, ~p"/api/beams", %{category: "drink"}), 422)
  end

  test "opening a received beam and marking it seen", %{conn: conn, me: me} do
    lea = located_user(:montmartre, %{"name" => "Léa"})
    befriend(me, lea)
    {:ok, beam} = Beams.start_beam(lea, %{"category" => "movie", "note" => "Dune"})
    {:ok, 1} = Beams.fan_out(beam.id)

    assert %{
             "beam" => %{
               "user" => %{"name" => "Léa"},
               "note" => "Dune",
               "active" => true,
               "distance_km" => 3
             }
           } =
             json_response(get(conn, ~p"/api/beams/#{beam.id}"), 200)

    assert response(post(conn, ~p"/api/beams/#{beam.id}/seen"), 204)
    assert {_, %{seen: 1}, []} = Beams.current_with_stats(lea)

    {stranger_conn, _} = authed(build_conn())
    assert json_response(get(stranger_conn, ~p"/api/beams/#{beam.id}"), 404)
    assert json_response(post(stranger_conn, ~p"/api/beams/#{beam.id}/seen"), 404)
  end

  test "mutes", %{conn: conn} do
    lea = user_fixture(%{"name" => "Léa"})
    assert response(post(conn, ~p"/api/mutes", %{user_id: lea.id}), 204)
    assert %{"muted" => [%{"name" => "Léa"}]} = json_response(get(conn, ~p"/api/mutes"), 200)
    assert response(delete(conn, ~p"/api/mutes/#{lea.id}"), 204)
    assert %{"muted" => []} = json_response(get(conn, ~p"/api/mutes"), 200)
  end
end
