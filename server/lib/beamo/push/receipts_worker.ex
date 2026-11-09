defmodule Beamo.Push.ReceiptsWorker do
  use Oban.Worker, queue: :push, max_attempts: 3

  alias Beamo.Push
  alias Beamo.Push.{Expo, SendWorker}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"receipts" => tokens_by_ticket}}) do
    with {:ok, receipts} <- Expo.get_receipts(Map.keys(tokens_by_ticket)) do
      receipts
      |> Enum.filter(fn {_, receipt} -> SendWorker.dead_token?(receipt) end)
      |> Enum.map(fn {ticket_id, _} -> tokens_by_ticket[ticket_id] end)
      |> Push.delete_tokens()

      :ok
    end
  end
end
