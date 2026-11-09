defmodule BeamoWeb.Plugs.ClientIp do
  def init(opts), do: opts

  def call(conn, _opts) do
    with header when is_binary(header) <- Application.get_env(:beamo, :client_ip_header),
         [value | _] <- Plug.Conn.get_req_header(conn, String.downcase(header)),
         {:ok, ip} <-
           value
           |> String.split(",")
           |> List.last()
           |> String.trim()
           |> to_charlist()
           |> :inet.parse_address() do
      %{conn | remote_ip: ip}
    else
      _ -> conn
    end
  end
end
