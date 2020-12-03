defmodule BoardGamesWeb.PlayGameController do
  use BoardGamesWeb, :controller

  import Phoenix.LiveView.Controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"game_id" => game_id, "player_name" => player_name}) do
    conn
    |> put_session(:player_name, player_name)
    |> redirect(to: Routes.play_game_path(conn, :show, game_id))
  end

  def show(conn, %{"game_id" => game_id}) do
    live_render(conn, BoardGamesWeb.SternhalmaLive,
      session:
        Map.merge(
          get_session(conn),
          %{"game_id" => game_id}
        )
    )
  end
end
