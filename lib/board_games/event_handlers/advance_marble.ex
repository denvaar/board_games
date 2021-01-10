defmodule BoardGames.EventHandlers.AdvanceMarble do
  @moduledoc """
  Logic concerned with advancing a marble's
  position along a path.
  """

  alias BoardGames.{Marble, GameState}

  @spec handle({Hex.t(), list(Cell.t())}, GameState.game_state()) ::
          {:ok, GameState.game_state()}
  def handle({_current_position, []}, state) do
    new_state = %{
      state
      | timer_ref: nil,
        turn: next_turn(state.turn, state.players)
    }

    BoardGames.PubSub.broadcast_game_update!(state.id, new_state)

    {:ok, new_state}
  end

  def handle({current_position, [next_spot | path]}, state) do
    marbles =
      update_marble_position(
        state.marbles,
        current_position,
        next_spot.position
      )

    timer_ref =
      Process.send_after(
        self(),
        {:advance_marble_along_path, next_spot.position, path},
        500
      )

    new_state = %{
      state
      | timer_ref: timer_ref,
        marbles: marbles
    }

    BoardGames.PubSub.broadcast_game_update!(state.id, new_state)

    {:ok, new_state}
  end

  @spec next_turn(String.t(), list(String.t())) :: String.t()
  defp next_turn(turn, players) do
    next_player_index =
      case Enum.find_index(players, &(&1 == turn)) do
        nil ->
          0

        current_player_index ->
          rem(current_player_index + 1, length(players))
      end

    Enum.at(players, next_player_index)
  end

  defp update_marble_position(marbles, current_position, target_position) do
    {x, y} = Sternhalma.to_pixel(target_position)

    marbles
    |> Enum.map(fn marble ->
      position = Sternhalma.from_pixel({marble.x, marble.y})

      if position == current_position do
        %Marble{
          marble
          | x: Float.round(x, 3),
            y: Float.round(y, 3)
        }
      else
        marble
      end
    end)
  end
end
