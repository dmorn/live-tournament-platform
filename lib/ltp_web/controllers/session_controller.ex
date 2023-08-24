defmodule LTPWeb.SessionController do
  use LTPWeb, :controller

  def login(conn, %{"token" => token}) do
    case Phoenix.Token.verify(LTPWeb.Endpoint, "auth", token, max_age: 86400 * 7) do
      {:ok, admin_id} ->
        conn
        |> put_flash(:info, "Login successful.")
        |> put_session(:admin_id, admin_id)
        |> redirect(to: ~p"/")

      _error ->
        conn
        |> put_flash(:error, "Invalid login URL.")
        |> redirect(to: ~p"/")
    end
  end
end
