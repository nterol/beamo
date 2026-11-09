defmodule Beamo.Accounts.OTP do
  @callback start(phone :: String.t()) :: :ok | {:error, term}
  @callback check(phone :: String.t(), code :: String.t()) :: :ok | {:error, :invalid_code | term}

  def start(phone) do
    if test_phone?(phone), do: :ok, else: provider().start(phone)
  end

  def check(phone, code) do
    if test_phone?(phone) do
      if Plug.Crypto.secure_compare(code, Application.fetch_env!(:beamo, :otp_test_code)),
        do: :ok,
        else: {:error, :invalid_code}
    else
      provider().check(phone, code)
    end
  end

  defp test_phone?(phone) do
    test_phone = Application.get_env(:beamo, :otp_test_phone)
    is_binary(test_phone) and test_phone != "" and phone == test_phone
  end

  defp provider, do: Application.fetch_env!(:beamo, :otp_provider)
end
