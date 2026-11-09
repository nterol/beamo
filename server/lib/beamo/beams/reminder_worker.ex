defmodule Beamo.Beams.ReminderWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"beam_id" => beam_id}}), do: Beamo.Beams.remind(beam_id)
end
