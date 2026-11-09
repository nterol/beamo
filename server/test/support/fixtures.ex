defmodule Beamo.Fixtures do
  alias Beamo.{Accounts, Social}

  def unique_phone, do: "+336" <> (Enum.map(1..8, fn _ -> Enum.random(0..9) end) |> Enum.join())

  def user_with_token(attrs \\ %{}) do
    {:ok, token, user, _new?} = Accounts.verify_and_login(unique_phone(), "000000")
    {:ok, user} = Accounts.update_settings(user, Map.merge(%{"name" => "User"}, attrs))
    {user, token}
  end

  def user_fixture(attrs \\ %{}), do: attrs |> user_with_token() |> elem(0)

  @places %{
    paris: {48.8566, 2.3522},
    montmartre: {48.8867, 2.3431},
    versailles: {48.8049, 2.1204},
    lyon: {45.764, 4.8357}
  }

  def located_user(place, attrs \\ %{}) do
    {lat, lng} = Map.fetch!(@places, place)
    user = user_fixture(attrs)
    {:ok, user} = Accounts.update_location(user, %{"lat" => lat, "lng" => lng})

    {:ok, _} =
      Beamo.Push.register_token(user, %{"token" => push_token(user), "platform" => "ios"})

    user
  end

  def push_token(user), do: "ExponentPushToken[#{user.id}]"

  def befriend(a, b) do
    {:ok, _} = Social.request_friendship(a, b.id)
    {:ok, friendship} = Social.request_friendship(b, a.id)
    friendship
  end
end
