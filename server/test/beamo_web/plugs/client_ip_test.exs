defmodule BeamoWeb.Plugs.ClientIpTest do
  use ExUnit.Case, async: false

  alias BeamoWeb.Plugs.ClientIp

  setup do
    on_exit(fn -> Application.delete_env(:beamo, :client_ip_header) end)
  end

  defp call(headers) do
    Enum.reduce(headers, Plug.Test.conn(:get, "/"), fn {k, v}, conn ->
      Plug.Conn.put_req_header(conn, k, v)
    end)
    |> ClientIp.call([])
  end

  test "keeps the socket address when no header is configured" do
    assert call([{"x-forwarded-for", "1.2.3.4"}]).remote_ip == {127, 0, 0, 1}
  end

  test "uses the last hop added by the trusted proxy" do
    Application.put_env(:beamo, :client_ip_header, "X-Forwarded-For")
    assert call([{"x-forwarded-for", "6.6.6.6, 1.2.3.4"}]).remote_ip == {1, 2, 3, 4}
    assert call([{"x-forwarded-for", "garbage"}]).remote_ip == {127, 0, 0, 1}
  end

  test "single-value headers such as Fly-Client-IP" do
    Application.put_env(:beamo, :client_ip_header, "fly-client-ip")
    assert call([{"fly-client-ip", "2001:db8::1"}]).remote_ip == {8193, 3512, 0, 0, 0, 0, 0, 1}
  end
end
