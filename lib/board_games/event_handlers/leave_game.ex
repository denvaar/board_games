defmodule BoardGames.EventHandlers.LeaveGame do
  @moduledoc """
  Logic concerned with updating game state in
  responses to a player leaving.
  """

  alias BoardGames.{EventHandlers, GameState}

  @spec handle({String.t()}, GameState.t()) :: {:ok, GameState.t()}
  def handle({player_name}, state) do
    {:ok, leave_game(state, state.status, player_name)}
  end

  @spec leave_game(GameState.t(), GameState.game_status(), String.t()) :: GameState.t()
  defp leave_game(state, :setup, player_name) do
    state.players
    |> Enum.reject(&(&1 == player_name))
    |> Enum.reduce(%GameState{id: state.id}, fn player_name, state_acc ->
      {:ok, new_state} = EventHandlers.JoinGame.handle({player_name}, state_acc)
      new_state
    end)
  end

  defp leave_game(state, _game_status, player_name) do
    %{state | connected_players: Enum.reject(state.connected_players, &(&1 == player_name))}
  end
end
