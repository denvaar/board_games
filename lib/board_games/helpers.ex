defmodule BoardGames.Helpers do
  @moduledoc """
  Shared functions that I don't know where to put otherwise...
  """

  @spec next_turn(String.t(), list(String.t())) :: String.t()
  def next_turn(turn, players) do
    next_player_index =
      case Enum.find_index(players, &(&1 == turn)) do
        nil ->
          0

        current_player_index ->
          rem(current_player_index + 1, length(players))
      end

    Enum.at(players, next_player_index)
  end
end
