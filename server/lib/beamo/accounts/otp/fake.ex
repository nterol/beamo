defmodule Beamo.Accounts.OTP.Fake do
  @behaviour Beamo.Accounts.OTP

  require Logger

  @code "000000"

  @impl true
  def start(phone) do
    Logger.info("[OTP.Fake] code for #{phone} is #{@code}")
    :ok
  end

  @impl true
  def check(_phone, @code), do: :ok
  def check(_phone, _code), do: {:error, :invalid_code}
end
