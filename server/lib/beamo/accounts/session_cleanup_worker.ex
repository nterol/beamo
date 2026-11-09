defmodule Beamo.Accounts.SessionCleanupWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  @impl Oban.Worker
  def perform(_job) do
    Beamo.Accounts.delete_expired_sessions()
    :ok
  end
end
