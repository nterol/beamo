defmodule BeamoWeb.SocialControllerTest do
  use BeamoWeb.ConnCase, async: true

  alias Beamo.Accounts.User

  setup %{conn: conn} do
    {conn, me} = authed(conn, %{"name" => "Me"})
    %{conn: conn, me: me}
  end

  describe "friend requests" do
    test "request then accept", %{conn: conn, me: me} do
      {other_conn, other} = authed(build_conn(), %{"name" => "Léa"})

      assert %{"id" => id, "status" => "pending"} =
               json_response(post(conn, ~p"/api/friend-requests", %{user_id: other.id}), 201)

      assert %{"incoming" => [%{"id" => ^id, "user" => %{"name" => "Me"}}]} =
               json_response(get(other_conn, ~p"/api/friend-requests"), 200)

      assert %{"status" => "accepted"} =
               json_response(post(other_conn, ~p"/api/friend-requests/#{id}/accept"), 200)

      assert %{"friends" => [%{"id" => other_id}]} =
               json_response(get(conn, ~p"/api/friends"), 200)

      assert other_id == other.id

      assert %{"friends" => [%{"name" => "Me"}]} =
               json_response(get(other_conn, ~p"/api/friends"), 200)

      assert Beamo.Social.friend_ids(me.id) == [other.id]
    end

    test "a crossed request accepts the pending one", %{conn: conn, me: me} do
      other = user_fixture()
      {:ok, _} = Beamo.Social.request_friendship(other, me.id)

      assert %{"status" => "accepted"} =
               json_response(post(conn, ~p"/api/friend-requests", %{user_id: other.id}), 201)
    end

    test "only the addressee can accept", %{conn: conn} do
      other = user_fixture()

      %{"id" => id} =
        json_response(post(conn, ~p"/api/friend-requests", %{user_id: other.id}), 201)

      assert json_response(post(conn, ~p"/api/friend-requests/#{id}/accept"), 404)
    end

    test "decline, unfriend, and bad targets", %{conn: conn, me: me} do
      other = user_fixture()

      %{"id" => id} =
        json_response(post(conn, ~p"/api/friend-requests", %{user_id: other.id}), 201)

      assert response(delete(conn, ~p"/api/friend-requests/#{id}"), 204)
      assert %{"outgoing" => []} = json_response(get(conn, ~p"/api/friend-requests"), 200)

      befriend(me, other)
      assert response(delete(conn, ~p"/api/friends/#{other.id}"), 204)
      assert %{"friends" => []} = json_response(get(conn, ~p"/api/friends"), 200)

      assert json_response(post(conn, ~p"/api/friend-requests", %{user_id: me.id}), 422)

      assert json_response(
               post(conn, ~p"/api/friend-requests", %{user_id: Ecto.UUID.generate()}),
               404
             )
    end
  end

  describe "blocks" do
    test "removes the friendship and hides both ways", %{conn: conn, me: me} do
      other = user_fixture()
      befriend(me, other)

      assert response(post(conn, ~p"/api/blocks", %{user_id: other.id}), 204)
      assert %{"friends" => []} = json_response(get(conn, ~p"/api/friends"), 200)
      assert %{"blocked" => [%{"id" => _}]} = json_response(get(conn, ~p"/api/blocks"), 200)

      assert {:error, :not_found} = Beamo.Social.request_friendship(other, me.id)

      assert response(delete(conn, ~p"/api/blocks/#{other.id}"), 204)
      assert {:ok, _} = Beamo.Social.request_friendship(other, me.id)
    end
  end

  describe "contact matching" do
    test "returns registered contacts with their relation", %{conn: conn, me: me} do
      friend = user_fixture()
      stranger = user_fixture()
      blocker = user_fixture()
      befriend(me, friend)
      :ok = Beamo.Social.block(blocker, me.id)

      hashes =
        [friend, stranger, blocker, me]
        |> Enum.map(&String.upcase(User.hash_phone(&1.phone)))
        |> Kernel.++([User.hash_phone("+33600000000")])

      %{"matches" => matches} =
        json_response(post(conn, ~p"/api/contacts/match", %{hashes: hashes}), 200)

      assert matches |> Enum.map(&{&1["id"], &1["relation"]}) |> Enum.sort() ==
               Enum.sort([{friend.id, "friend"}, {stranger.id, "none"}])
    end

    test "caps the batch size", %{conn: conn} do
      hashes = for i <- 1..2001, do: Integer.to_string(i)

      assert %{"error" => "too_many_items"} =
               json_response(post(conn, ~p"/api/contacts/match", %{hashes: hashes}), 422)
    end
  end
end
