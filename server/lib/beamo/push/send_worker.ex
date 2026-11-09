defmodule Beamo.Push.SendWorker do
  use Oban.Worker, queue: :push, max_attempts: 5

  alias Beamo.Push
  alias Beamo.Push.{Expo, ReceiptsWorker}

  @receipts_delay 15 * 60

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"messages" => messages}}) do
    with {:ok, tickets} <- Expo.send_messages(messages) do
      pairs = Enum.zip(messages, tickets)

      pairs
      |> Enum.filter(fn {_, t} -> dead_token?(t) end)
      |> Enum.map(fn {m, _} -> m["to"] end)
      |> Push.delete_tokens()

      receipts =
        for {m, %{"status" => "ok", "id" => id}} <- pairs, into: %{}, do: {id, m["to"]}

      if map_size(receipts) > 0 do
        %{"receipts" => receipts}
        |> ReceiptsWorker.new(schedule_in: @receipts_delay)
        |> Oban.insert!()
      end

      :ok
    end
  end

  def dead_token?(%{"status" => "error", "details" => %{"error" => "DeviceNotRegistered"}}),
    do: true

  def dead_token?(_), do: false
end
