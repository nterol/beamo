defmodule BeamoWeb.UserChannelTest do
  use BeamoWeb.ChannelCase, async: true

  alias Beamo.{Beams, Communities, Social}
  alias BeamoWeb.UserSocket

  defp join!(user) do
    {:ok, socket} = connect(UserSocket, %{"token" => session_token(user)})
    {:ok, _, socket} = subscribe_and_join(socket, "user:#{user.id}", %{})
    socket
  end

  test "rejects bad tokens and other users' topics" do
    assert :error = connect(UserSocket, %{"token" => "nope"})
    assert :error = connect(UserSocket, %{})

    me = user_fixture()
    other = user_fixture()
    {:ok, socket} = connect(UserSocket, %{"token" => session_token(me)})

    assert {:error, %{reason: "unauthorized"}} =
             subscribe_and_join(socket, "user:#{other.id}", %{})
  end

  test "friends and community members hear about beams, strangers do not" do
    tom = located_user(:paris, %{"name" => "Tom"})
    lea = located_user(:montmartre, %{"name" => "Léa"})
    max = located_user(:montmartre, %{"name" => "Max"})
    stranger = located_user(:montmartre)
    befriend(tom, lea)
    befriend(lea, max)

    {:ok, community} =
      Communities.create_community(lea, %{"name" => "Foot", "user_ids" => [tom.id, max.id]})

    :ok = Communities.accept(tom, community.id)
    :ok = Communities.accept(max, community.id)

    join!(lea)
    join!(max)
    join!(stranger)

    {:ok, beam} = Beams.start_beam(tom, %{"category" => "drink"})
    assert_push "feed_changed", %{}
    assert_push "feed_changed", %{}
    refute_push "feed_changed", %{}

    :ok = Beams.end_beam(tom)
    assert_push "feed_changed", %{}
    assert_push "feed_changed", %{}

    Beamo.Repo.update_all(Beamo.Beams.Beam,
      set: [ended_at: nil, expires_at: DateTime.add(DateTime.utc_now(:second), -1)]
    )

    :ok = Beams.expire(beam.id)
    assert_push "feed_changed", %{}
    assert Beamo.Repo.get!(Beamo.Beams.Beam, beam.id).ended_at
  end

  test "friend and community changes" do
    me = user_fixture()
    other = user_fixture()
    join!(me)

    {:ok, _} = Social.request_friendship(other, me.id)
    assert_push "friends_changed", %{}

    befriend(me, other)

    {:ok, community} =
      Communities.create_community(other, %{"name" => "X", "user_ids" => [me.id]})

    assert_push "invitations_changed", %{}

    :ok = Communities.accept(me, community.id)
    community_id = community.id
    assert_push "community_changed", %{community_id: ^community_id}
  end

  test "logout closes the socket" do
    user = user_fixture()
    {:ok, token, _user, _} = Beamo.Accounts.verify_and_login(user.phone, "000000")
    {:ok, socket} = connect(UserSocket, %{"token" => token})
    {:ok, user, session} = Beamo.Accounts.authenticate(token)
    assert socket.assigns.user_id == user.id
    assert UserSocket.id(socket) == "session_socket:#{session.id}"
  end
end
