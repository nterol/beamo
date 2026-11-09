defmodule Beamo.PushTest do
  use Beamo.DataCase, async: true
  use Oban.Testing, repo: Beamo.Repo

  alias Beamo.Push
  alias Beamo.Push.{PushToken, ReceiptsWorker, SendWorker}

  defp token(n), do: "ExponentPushToken[#{n}]"

  setup do
    user = user_fixture()
    {:ok, _} = Push.register_token(user, %{"token" => token("a"), "platform" => "ios"})
    {:ok, _} = Push.register_token(user, %{"token" => token("b"), "platform" => "android"})
    %{user: user}
  end

  test "rejects tokens that are not Expo tokens", %{user: user} do
    assert {:error, _} = Push.register_token(user, %{"token" => "abc", "platform" => "ios"})
  end

  test "a re-registered token moves to the new user", %{user: user} do
    other = user_fixture()
    {:ok, _} = Push.register_token(other, %{"token" => token("a"), "platform" => "ios"})
    assert Repo.get_by!(PushToken, token: token("a")).user_id == other.id
    assert Repo.get_by!(PushToken, token: token("b")).user_id == user.id
  end

  test "notify queues one batch for every device", %{user: user} do
    assert {:ok, 2} = Push.notify([user.id], %{title: "Léa", body: "est dispo"})
    assert_enqueued(worker: SendWorker)
    [job] = all_enqueued(worker: SendWorker)
    assert job.args["messages"] |> Enum.map(& &1["to"]) |> Enum.sort() == [token("a"), token("b")]
  end

  test "sending purges dead tokens and schedules receipts" do
    Req.Test.stub(Push.Expo, fn conn ->
      Req.Test.json(conn, %{
        "data" => [
          %{"status" => "ok", "id" => "ticket-a"},
          %{"status" => "error", "details" => %{"error" => "DeviceNotRegistered"}}
        ]
      })
    end)

    messages = [%{"to" => token("a")}, %{"to" => token("b")}]
    assert :ok = perform_job(SendWorker, %{"messages" => messages})

    assert Repo.get_by(PushToken, token: token("a"))
    refute Repo.get_by(PushToken, token: token("b"))
    assert_enqueued(worker: ReceiptsWorker, args: %{"receipts" => %{"ticket-a" => token("a")}})
  end

  test "receipts purge tokens reported dead later" do
    Req.Test.stub(Push.Expo, fn conn ->
      Req.Test.json(conn, %{
        "data" => %{
          "ticket-a" => %{"status" => "error", "details" => %{"error" => "DeviceNotRegistered"}}
        }
      })
    end)

    assert :ok = perform_job(ReceiptsWorker, %{"receipts" => %{"ticket-a" => token("a")}})
    refute Repo.get_by(PushToken, token: token("a"))
  end

  test "an Expo outage makes the job retry" do
    Req.Test.stub(Push.Expo, &Plug.Conn.send_resp(&1, 503, "down"))
    assert {:error, _} = perform_job(SendWorker, %{"messages" => [%{"to" => token("a")}]})
  end
end
