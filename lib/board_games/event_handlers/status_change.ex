defmodule BoardGames.EventHandlers.StatusChange do
  @moduledoc """
  Logic concerned with updating game state when
  the game status changes.
  """

  alias BoardGames.GameState

  @spec handle({GameState.game_status()}, GameState.game_state()) ::
          {:ok, GameState.game_state()} | {:error, {atom(), GameState.game_state()}}
  def handle({status}, state) do
    state
    |> change_game_status(status)
    |> perform_side_effects(status)
  end

  @spec change_game_status(GameState.game_state(), GameState.game_status()) ::
          {:ok | :error, GameState.game_state()}
  defp change_game_status(game_state, :playing)
       when length(game_state.players) > 1 and game_state.status == :setup,
       do: {:ok, %{game_state | status: :playing}}

  defp change_game_status(game_state, :over) when game_state.status == :playing,
    do: {:ok, %{game_state | status: :over}}

  defp change_game_status(game_state, _), do: {:error, game_state}

  @spec perform_side_effects({:ok | :error, GameState.game_state()}, GameState.game_status()) ::
          {:ok | :error, GameState.game_state()}
  defp perform_side_effects({:ok, game_state}, :playing) do
    {:ok, %{game_state | turn: List.first(game_state.players)}}
  end

  defp perform_side_effects({:ok, game_state}, _), do: {:ok, game_state}
  defp perform_side_effects({:error, game_state}, _), do: {:error, game_state}
end
