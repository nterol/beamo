defmodule BeamoWeb.AuthController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Accounts
  alias Beamo.Accounts.User
  alias BeamoWeb.Plugs.RateLimit

  alias BeamoWeb.Schemas

  tags(["auth"])

  operation(:start,
    summary: "Envoyer un code OTP par SMS",
    description: "Répond toujours 204 pour un numéro bien formé.",
    security: [],
    request_body: Schemas.json("Numéro", Schemas.OtpStartRequest),
    responses: [no_content: "Code envoyé"] ++ Schemas.errors()
  )

  operation(:verify,
    summary: "Vérifier le code et ouvrir une session",
    security: [],
    request_body: Schemas.json("Numéro et code", Schemas.OtpVerifyRequest),
    responses: [ok: Schemas.json("Session ouverte", Schemas.AuthResponse)] ++ Schemas.errors()
  )

  operation(:logout,
    summary: "Fermer la session courante",
    responses: [no_content: "Session fermée"] ++ Schemas.errors()
  )

  action_fallback BeamoWeb.FallbackController

  @ten_minutes :timer.minutes(10)

  plug RateLimit,
       [name: :otp_start_ip, by: :ip, limit: 10, scale: @ten_minutes] when action == :start

  plug RateLimit,
       [name: :otp_start_phone, by: {:param, "phone"}, limit: 3, scale: @ten_minutes]
       when action == :start

  plug RateLimit,
       [name: :otp_verify_ip, by: :ip, limit: 30, scale: @ten_minutes] when action == :verify

  plug RateLimit,
       [name: :otp_verify_phone, by: {:param, "phone"}, limit: 10, scale: @ten_minutes]
       when action == :verify

  def start(conn, %{"phone" => phone}) do
    if User.e164?(phone) do
      _ = Accounts.start_verification(phone)
      send_resp(conn, :no_content, "")
    else
      {:error, :invalid}
    end
  end

  def start(_conn, _params), do: {:error, :invalid}

  def verify(conn, %{"phone" => phone, "code" => code})
      when is_binary(phone) and is_binary(code) do
    with true <- User.e164?(phone) || {:error, :invalid},
         {:ok, token, user, new?} <- Accounts.verify_and_login(phone, code) do
      json(conn, %{token: token, user: BeamoWeb.UserJSON.me(user), is_new: new?})
    end
  end

  def verify(_conn, _params), do: {:error, :invalid}

  def logout(conn, _params) do
    Accounts.delete_session(conn.assigns.session)
    BeamoWeb.UserSocket.disconnect(conn.assigns.session.id)
    send_resp(conn, :no_content, "")
  end
end
