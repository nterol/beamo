defmodule Beamo.Accounts.OTP.Prelude do
  @behaviour Beamo.Accounts.OTP

  require Logger

  @impl true
  def start(phone) do
    case post("/v2/verification", %{target: target(phone)}) do
      {:ok, %{status: 200}} -> :ok
      other -> failure(:start, other)
    end
  end

  @impl true
  def check(phone, code) do
    case post("/v2/verification/check", %{target: target(phone), code: code}) do
      {:ok, %{status: 200, body: %{"status" => "success"}}} -> :ok
      {:ok, %{status: 200}} -> {:error, :invalid_code}
      other -> failure(:check, other)
    end
  end

  defp target(phone), do: %{type: "phone_number", value: phone}

  defp post(path, body) do
    [
      base_url: "https://api.prelude.dev",
      url: path,
      json: body,
      auth: {:bearer, Application.get_env(:beamo, :prelude_api_key)},
      retry: false
    ]
    |> Keyword.merge(Application.get_env(:beamo, :prelude_req_options, []))
    |> Req.post()
  end

  defp failure(step, result) do
    Logger.error("[OTP.Prelude] #{step} failed: #{inspect(result)}")
    {:error, :provider_error}
  end
end
