defmodule BeamoWeb.AuthControllerTest do
  use BeamoWeb.ConnCase, async: true

  describe "POST /api/auth/otp/start" do
    test "answers 204 for any well-formed number", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/otp/start", %{phone: unique_phone()})
      assert response(conn, 204)
    end

    test "rejects a malformed number", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/otp/start", %{phone: "0612345678"})
      assert %{"error" => "invalid"} = json_response(conn, 422)
    end

    test "limits sends per phone number", %{conn: conn} do
      phone = unique_phone()

      for _ <- 1..3,
          do: assert(response(post(conn, ~p"/api/auth/otp/start", %{phone: phone}), 204))

      conn = post(conn, ~p"/api/auth/otp/start", %{phone: phone})
      assert json_response(conn, 429)
      assert [_] = get_resp_header(conn, "retry-after")
    end
  end

  describe "POST /api/auth/otp/verify" do
    test "signs up a new user", %{conn: conn} do
      phone = unique_phone()
      conn = post(conn, ~p"/api/auth/otp/verify", %{phone: phone, code: "000000"})

      assert %{"token" => token, "is_new" => true, "user" => %{"phone" => ^phone, "name" => nil}} =
               json_response(conn, 200)

      assert is_binary(token)
    end

    test "logs an onboarded user back in", %{conn: conn} do
      user = user_fixture(%{"name" => "Léa"})
      conn = post(conn, ~p"/api/auth/otp/verify", %{phone: user.phone, code: "000000"})
      assert %{"is_new" => false, "user" => %{"id" => id}} = json_response(conn, 200)
      assert id == user.id
    end

    test "rejects a wrong code", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/otp/verify", %{phone: unique_phone(), code: "123456"})
      assert %{"error" => "invalid_code"} = json_response(conn, 401)
    end
  end

  describe "sessions" do
    test "requires a bearer token", %{conn: conn} do
      assert json_response(get(conn, ~p"/api/me"), 401)
      conn = put_req_header(conn, "authorization", "Bearer nope")
      assert json_response(get(conn, ~p"/api/me"), 401)
    end

    test "logout revokes the token", %{conn: conn} do
      {conn, _user} = authed(conn)
      assert json_response(get(conn, ~p"/api/me"), 200)
      assert response(delete(conn, ~p"/api/auth/session"), 204)
      assert json_response(get(conn, ~p"/api/me"), 401)
    end

    test "expired sessions are purged by the daily job", %{conn: conn} do
      {conn, user} = authed(conn)
      past = DateTime.add(DateTime.utc_now(:second), -1)
      Beamo.Repo.update_all(Beamo.Accounts.Session, set: [expires_at: past])

      assert :ok = Beamo.Accounts.SessionCleanupWorker.perform(%Oban.Job{})
      refute Beamo.Repo.get_by(Beamo.Accounts.Session, user_id: user.id)
      assert json_response(get(conn, ~p"/api/me"), 401)
    end

    test "slides the expiry of an ageing session", %{conn: conn} do
      {conn, user} = authed(conn)
      soon = DateTime.add(DateTime.utc_now(:second), 10, :day)
      Beamo.Repo.update_all(Beamo.Accounts.Session, set: [expires_at: soon])

      assert json_response(get(conn, ~p"/api/me"), 200)
      session = Beamo.Repo.get_by!(Beamo.Accounts.Session, user_id: user.id)
      assert DateTime.diff(session.expires_at, DateTime.utc_now(), :day) >= 89
    end
  end
end
