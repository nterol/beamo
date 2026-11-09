defmodule Beamo.Realtime do
  def subscribe(user_id), do: Phoenix.PubSub.subscribe(Beamo.PubSub, topic(user_id))

  def notify(user_ids, event, payload \\ %{}) do
    for id <- Enum.uniq(user_ids) do
      Phoenix.PubSub.broadcast(Beamo.PubSub, topic(id), {:realtime, event, payload})
    end

    :ok
  end

  defp topic(user_id), do: "realtime:user:#{user_id}"
end
