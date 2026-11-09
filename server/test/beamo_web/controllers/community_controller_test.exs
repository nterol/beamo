defmodule BeamoWeb.CommunityControllerTest do
  use BeamoWeb.ConnCase, async: true
  use Oban.Testing, repo: Beamo.Repo

  alias Beamo.{Beams, Communities}

  setup %{conn: conn} do
    {lea_conn, lea} = authed(conn, %{"name" => "Léa"})
    {:ok, lea} = Beamo.Accounts.update_location(lea, %{"lat" => 48.8566, "lng" => 2.3522})
    tom = located_user(:montmartre, %{"name" => "Tom"})
    max = located_user(:montmartre, %{"name" => "Max"})
    befriend(lea, tom)
    befriend(lea, max)
    %{conn: lea_conn, lea: lea, tom: tom, max: max}
  end

  defp create!(conn, ids) do
    %{"id" => id} =
      json_response(post(conn, ~p"/api/communities", %{name: " Foot ", user_ids: ids}), 201)

    id
  end

  defp conn_for(user) do
    token = Beamo.Fixtures.session_token(user)
    put_req_header(build_conn(), "authorization", "Bearer " <> token)
  end

  test "Léa brings Tom and Max together", %{conn: conn, lea: lea, tom: tom, max: max} do
    id = create!(conn, [tom.id, max.id])

    assert %{"name" => "Foot", "members" => members} =
             json_response(get(conn, ~p"/api/communities/#{id}"), 200)

    assert [
             %{"status" => "member", "user" => %{"name" => "Léa"}},
             %{"status" => "invited", "user" => nil, "invited_by" => %{"name" => "Léa"}},
             %{"status" => "invited", "user" => nil}
           ] = members

    tom_conn = conn_for(tom)

    assert %{
             "invitations" => [
               %{"community" => %{"name" => "Foot"}, "invited_by" => %{"name" => "Léa"}}
             ]
           } =
             json_response(get(tom_conn, ~p"/api/community-invitations"), 200)

    assert json_response(get(tom_conn, ~p"/api/communities/#{id}"), 404)
    assert response(post(tom_conn, ~p"/api/communities/#{id}/accept"), 204)
    assert response(post(conn_for(max), ~p"/api/communities/#{id}/accept"), 204)

    assert %{"communities" => [%{"name" => "Foot", "member_count" => 3}]} =
             json_response(get(tom_conn, ~p"/api/communities"), 200)

    {:ok, _} = Beams.start_beam(max, %{"category" => "sport"})

    assert %{"active" => false, "active_count" => 1, "members" => blurred} =
             json_response(get(tom_conn, ~p"/api/communities/#{id}"), 200)

    assert Enum.all?(blurred, &is_nil(&1["beam"]))

    {:ok, _} = Beams.start_beam(tom, %{"category" => "sport"})

    %{"active" => true, "members" => members} =
      json_response(get(tom_conn, ~p"/api/communities/#{id}"), 200)

    assert %{"user" => %{"name" => "Max"}, "beam" => %{"category" => "sport"}, "distance_km" => 1} =
             Enum.find(members, &(&1["user"]["name"] == "Max"))

    refute Beamo.Social.friends?(tom.id, max.id)
    assert Beamo.Social.circle_ids(tom.id) == [lea.id]
  end

  test "invitees must be friends of the inviter", %{conn: conn, tom: tom} do
    stranger = user_fixture()

    assert json_response(
             post(conn, ~p"/api/communities", %{name: "X", user_ids: [stranger.id]}),
             422
           )

    assert json_response(post(conn, ~p"/api/communities", %{name: "X", user_ids: []}), 422)

    id = create!(conn, [tom.id])

    assert %{"error" => "not_friends"} =
             json_response(
               post(conn, ~p"/api/communities/#{id}/invitations", %{user_ids: [stranger.id]}),
               422
             )
  end

  test "any member invites their own friends", %{conn: conn, lea: lea, tom: tom, max: max} do
    id = create!(conn, [tom.id])
    :ok = Communities.accept(tom, id)
    sam = user_fixture(%{"name" => "Sam"})
    befriend(tom, sam)

    assert %{"invited" => 1} =
             json_response(
               post(conn_for(tom), ~p"/api/communities/#{id}/invitations", %{
                 user_ids: [sam.id, lea.id]
               }),
               200
             )

    assert %{"invited" => 0} =
             json_response(
               post(conn, ~p"/api/communities/#{id}/invitations", %{user_ids: [tom.id]}),
               200
             )

    assert json_response(
             post(conn_for(max), ~p"/api/communities/#{id}/invitations", %{user_ids: [lea.id]}),
             404
           )
  end

  test "leaving, declining and the last one out", %{conn: conn, tom: tom, max: max} do
    id = create!(conn, [tom.id, max.id])
    assert response(delete(conn_for(max), ~p"/api/communities/#{id}/membership"), 204)
    :ok = Communities.accept(tom, id)

    assert response(delete(conn, ~p"/api/communities/#{id}/membership"), 204)
    assert {:ok, _} = Communities.get_community(tom, id)
    assert :ok = Communities.leave(tom, id)
    refute Beamo.Repo.get(Communities.Community, id)
  end

  test "renaming and blocked members", %{conn: conn, lea: lea, tom: tom} do
    id = create!(conn, [tom.id])
    :ok = Communities.accept(tom, id)

    assert %{"name" => "Five"} =
             json_response(patch(conn, ~p"/api/communities/#{id}", %{name: "Five"}), 200)

    :ok = Beamo.Social.block(tom, lea.id)

    assert %{"members" => [%{"user" => %{"name" => "Léa"}}]} =
             json_response(get(conn, ~p"/api/communities/#{id}"), 200)
  end

  test "invitees get a push", %{conn: conn, tom: tom} do
    create!(conn, [tom.id])
    [job] = all_enqueued(worker: Beamo.Push.SendWorker)

    assert [%{"title" => "Léa t'invite dans « Foot »", "data" => %{"type" => "community_invite"}}] =
             job.args["messages"]
  end
end
