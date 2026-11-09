defmodule Beamo.Push do
  import Ecto.Query

  alias Beamo.Accounts.User
  alias Beamo.Push.{Expo, PushToken, SendWorker}
  alias Beamo.Repo

  def register_token(%User{id: user_id}, attrs) do
    %PushToken{user_id: user_id}
    |> PushToken.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:user_id, :platform, :updated_at]},
      conflict_target: :token,
      returning: true
    )
  end

  def delete_token(%User{id: user_id}, token) do
    Repo.delete_all(from t in PushToken, where: t.user_id == ^user_id and t.token == ^token)
    :ok
  end

  def delete_tokens([]), do: :ok

  def delete_tokens(tokens) do
    Repo.delete_all(from t in PushToken, where: t.token in ^tokens)
    :ok
  end

  def notify([], _message), do: {:ok, 0}

  def notify(user_ids, message) do
    tokens = Repo.all(from t in PushToken, where: t.user_id in ^user_ids, select: t.token)

    tokens
    |> Enum.map(&expo_message(&1, message))
    |> Enum.chunk_every(Expo.max_batch())
    |> Enum.map(&SendWorker.new(%{"messages" => &1}))
    |> Oban.insert_all()

    {:ok, length(tokens)}
  end

  defp expo_message(token, message) do
    %{
      "to" => token,
      "title" => message.title,
      "body" => message.body,
      "data" => Map.get(message, :data, %{}),
      "sound" => "default"
    }
  end
end
