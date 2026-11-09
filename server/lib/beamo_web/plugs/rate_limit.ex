defmodule BeamoWeb.Plugs.RateLimit do
  import Plug.Conn

  def init(opts), do: Map.new(opts)

  def call(conn, %{name: name, by: by, limit: limit, scale: scale}) do
    case Beamo.RateLimit.hit({name, key(conn, by)}, scale, limit) do
      {:allow, _count} ->
        conn

      {:deny, retry_after_ms} ->
        conn
        |> put_resp_header("retry-after", Integer.to_string(div(retry_after_ms, 1000) + 1))
        |> put_status(:too_many_requests)
        |> Phoenix.Controller.json(%{error: "too_many_requests"})
        |> halt()
    end
  end

  defp key(conn, :ip), do: conn.remote_ip
  defp key(conn, :user), do: conn.assigns.current_user.id
  defp key(conn, {:param, param}), do: to_string(conn.params[param])
end
