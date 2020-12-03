defmodule BoardGamesWeb.PlayGameControllerTest do
  use BoardGamesWeb.ConnCase

  describe "new" do
    test "renders join game form", %{conn: conn} do
      conn = get(conn, Routes.play_game_path(conn, :new))
      assert html_response(conn, 200) =~ "Join game"
    end
  end

  describe "create" do
    test "adds player name to session and redirects", %{conn: conn} do
      game_id = "test_game_1"
      player_name = "denvaar"

      conn =
        post(
          conn,
          Routes.play_game_path(conn, :create),
          game_id: game_id,
          player_name: player_name
        )

      assert %{game_id: game_id} = redirected_params(conn)
      assert %{"player_name" => ^player_name} = get_session(conn)
      assert redirected_to(conn) == Routes.play_game_path(conn, :show, game_id)
    end
  end
end
