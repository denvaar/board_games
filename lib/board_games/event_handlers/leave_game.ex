defmodule BoardGames.EventHandlers.LeaveGame do
  @moduledoc """
  Logic concerned with updating game state in
  responses to a player leaving.
  """

  alias BoardGames.{SternhalmaAdapter, GameState}

  @spec handle({String.t()}, GameState.game_state()) :: {:ok, GameState.game_state()}
  def handle({player_name}, state) do
    if state.status == :setup do
      remaining_players = Enum.reject(state.players, &(&1 == player_name))

      new_state = %{
        state
        | board: Sternhalma.empty_board(),
          marbles: [],
          players: [],
          marble_colors: %{}
      }

      final_state =
        remaining_players
        |> Enum.reduce(new_state, fn player_name, state_acc ->
          {:ok, new_state} = BoardGames.EventHandlers.JoinGame.handle({player_name}, state_acc)
          new_state
        end)

      {:ok, final_state}
    else
      {:ok, state}
    end
  end

  @spec update_players(GameState.game_state(), String.t()) :: GameState.game_state()
  defp update_players(state, player_name) do
    %{state | players: Enum.reject(state.players, &(&1 == player_name))}
  end

  @spec update_marble_color_mapping(GameState.game_state(), String.t()) :: GameState.game_state()
  defp update_marble_color_mapping(state, player_name) do
    %{state | marble_colors: Map.delete(state.marble_colors, player_name)}
  end

  @spec update_marbles(GameState.game_state(), String.t()) :: GameState.game_state()
  defp update_marbles(state, player_name) do
    %{
      state
      | marbles:
          state.marbles
          |> Enum.reject(&(&1.belongs_to == player_name))
    }
  end

  @spec update_board(GameState.game_state()) :: GameState.game_state()
  defp update_board(state) do
    board =
      state.players
      |> Enum.reduce(Sternhalma.empty_board(), fn p, board ->
        {:ok, b} = SternhalmaAdapter.setup_marbles(board, p)
        b
      end)

    %{state | board: Enum.reject(board, & &1.marble)}
  end
end
