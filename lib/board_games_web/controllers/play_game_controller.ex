defmodule BoardGamesWeb.PlayGameController do
  @moduledoc """
  Phoenix controller responsible for handling
  HTTP requests.

  This controller is set up to handle requests
  to several routes, which all end up with a player
  joining a game.
  """

  use BoardGamesWeb, :controller

  import Phoenix.LiveView.Controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"game_id" => game_id, "player_name" => player_name})
      when player_name != "" and game_id != "" do
    conn
    |> put_session(:player_name, player_name)
    |> redirect(to: Routes.play_game_path(conn, :show, game_id))
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Game code and player name are both required.")
    |> render("new.html")
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
