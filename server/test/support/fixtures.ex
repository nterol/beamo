defmodule Beamo.Fixtures do
  alias Beamo.{Accounts, Social}

  def unique_phone, do: "+336" <> (Enum.map(1..8, fn _ -> Enum.random(0..9) end) |> Enum.join())

  def user_with_token(attrs \\ %{}) do
    {:ok, token, user, _new?} = Accounts.verify_and_login(unique_phone(), "000000")
    {:ok, user} = Accounts.update_settings(user, Map.merge(%{"name" => "User"}, attrs))
    {user, token}
  end

  def user_fixture(attrs \\ %{}), do: attrs |> user_with_token() |> elem(0)

  def befriend(a, b) do
    {:ok, _} = Social.request_friendship(a, b.id)
    {:ok, friendship} = Social.request_friendship(b, a.id)
    friendship
  end
end
