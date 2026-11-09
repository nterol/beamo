defmodule Beamo.Beams.ExpireWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"beam_id" => beam_id}}), do: Beamo.Beams.expire(beam_id)
end
