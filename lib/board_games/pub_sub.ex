defmodule BoardGames.PubSub do
  @moduledoc """
  Module to encapsulate functions for working with PubSub.

  PubSub is used to subscribe and send game state updates
  between LiveView processes.
  """

  @spec subscribe_to_game_updates(String.t()) :: String.t()
  def subscribe_to_game_updates(game_id) do
    game_id
    |> topic()
    |> BoardGamesWeb.Endpoint.subscribe()

    game_id
  end

  @spec broadcast_game_update!(String.t(), BoardGames.GameState.t()) :: :ok
  def broadcast_game_update!(game_id, game) do
    game_id
    |> topic()
    |> BoardGamesWeb.Endpoint.broadcast!("game_state_update", game)
  end

  @spec topic(String.t()) :: String.t()
  defp topic(game_id) do
    "sternhalma:#{game_id}"
  end
end
