defmodule BeamoWeb.Plugs.Auth do
  import Plug.Conn

  alias Beamo.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user, session} <- Accounts.authenticate(token) do
      conn
      |> assign(:current_user, user)
      |> assign(:session, session)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "unauthorized"})
        |> halt()
    end
  end
end
