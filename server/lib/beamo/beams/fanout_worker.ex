defmodule Beamo.Beams.FanoutWorker do
  use Oban.Worker, queue: :default, max_attempts: 5, unique: [keys: [:beam_id]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"beam_id" => beam_id}}) do
    with {:ok, _count} <- Beamo.Beams.fan_out(beam_id), do: :ok
  end
end
