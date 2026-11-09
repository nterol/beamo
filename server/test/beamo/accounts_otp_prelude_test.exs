defmodule Beamo.Accounts.OTP.PreludeTest do
  use ExUnit.Case, async: true

  alias Beamo.Accounts.OTP.Prelude

  test "start and check map Prelude responses" do
    Req.Test.stub(Prelude, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      case {conn.request_path, Jason.decode!(body)} do
        {"/v2/verification", %{"target" => %{"value" => "+33611111111"}}} ->
          Req.Test.json(conn, %{"status" => "success"})

        {"/v2/verification/check", %{"code" => "111111"}} ->
          Req.Test.json(conn, %{"status" => "success"})

        {"/v2/verification/check", _} ->
          Req.Test.json(conn, %{"status" => "failure"})
      end
    end)

    assert :ok = Prelude.start("+33611111111")
    assert :ok = Prelude.check("+33611111111", "111111")
    assert {:error, :invalid_code} = Prelude.check("+33611111111", "222222")
  end

  test "a provider error is not an invalid code" do
    Req.Test.stub(Prelude, &Plug.Conn.send_resp(&1, 500, "boom"))

    ExUnit.CaptureLog.capture_log(fn ->
      assert {:error, :provider_error} = Prelude.check("+33611111111", "111111")
    end)
  end
end
