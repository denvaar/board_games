defmodule BoardGames.PubSub do
  def subscribe_to_game_updates(game_id) do
    game_id
    |> topic()
    |> BoardGamesWeb.Endpoint.subscribe()

    game_id
  end

  def broadcast_game_update!(game_id, game) do
    game_id
    |> topic()
    |> BoardGamesWeb.Endpoint.broadcast!("game_state_update", game)
  end

  defp topic(game_id) do
    "sternhalma:#{game_id}"
  end
end
