defmodule Beamo.Push.Expo do
  @max_batch 100

  def max_batch, do: @max_batch

  def send_messages(messages) when length(messages) <= @max_batch do
    case request("/--/api/v2/push/send", messages) do
      {:ok, %{status: 200, body: %{"data" => tickets}}} when is_list(tickets) -> {:ok, tickets}
      other -> {:error, other}
    end
  end

  def get_receipts(ids) do
    case request("/--/api/v2/push/getReceipts", %{ids: ids}) do
      {:ok, %{status: 200, body: %{"data" => receipts}}} when is_map(receipts) -> {:ok, receipts}
      other -> {:error, other}
    end
  end

  defp request(path, body) do
    token = Application.get_env(:beamo, :expo_access_token)

    [base_url: "https://exp.host", url: path, json: body, retry: false]
    |> then(&if(token, do: Keyword.put(&1, :auth, {:bearer, token}), else: &1))
    |> Keyword.merge(Application.get_env(:beamo, :expo_req_options, []))
    |> Req.post()
  end
end
