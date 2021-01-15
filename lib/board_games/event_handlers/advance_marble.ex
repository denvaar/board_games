defmodule BoardGames.EventHandlers.AdvanceMarble do
  @moduledoc """
  Logic concerned with advancing a marble's
  position along a path.
  """

  alias BoardGames.{Marble, Helpers, GameState, EventHandlers, SternhalmaAdapter}

  @spec handle({Sternhalma.Hex.t(), list(Sternhalma.Cell.t())}, GameState.t()) ::
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}}
  def handle({_current_position, []}, state) do
    winner = SternhalmaAdapter.winner(state.board)

    with {:ok, new_state} <- change_game_status(winner, state) do
      ref =
        Process.send_after(
          self(),
          {:tick, 0, :keep_turn},
          1_000
        )

      new_state = %{
        new_state
        | timer_ref: nil,
          winner: winner,
          turn_timer_ref: ref,
          seconds_remaining: 0,
          turn: Helpers.next_turn(state.turn, state.players)
      }

      BoardGames.PubSub.broadcast_game_update!(state.id, new_state)

      {:ok, new_state}
    end
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

    cancel_tick_timer(state.turn_timer_ref)

    new_state = %{
      state
      | timer_ref: timer_ref,
        turn_timer_ref: nil,
        marbles: marbles
    }

    BoardGames.PubSub.broadcast_game_update!(state.id, new_state)

    {:ok, new_state}
  end

  @spec update_marble_position(list(Marble.t()), Sternhalma.Hex.t(), Sternhalma.Hex.t()) ::
          list(Marble.t())
  defp update_marble_position(marbles, current_position, target_position) do
    {x, y} = Sternhalma.to_pixel(target_position)

    marbles
    |> Enum.map(fn marble ->
      position = Sternhalma.from_pixel({marble.x, marble.y})

      if position == current_position do
        %Marble{marble | x: Float.round(x, 3), y: Float.round(y, 3)}
      else
        marble
      end
    end)
  end

  @spec change_game_status(nil | String.t(), GameState.t()) ::
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}}
  defp change_game_status(nil, state), do: {:ok, state}
  defp change_game_status(_winner, state), do: EventHandlers.StatusChange.handle({:over}, state)

  @spec cancel_tick_timer(nil | reference()) :: non_neg_integer() | false | :ok
  defp cancel_tick_timer(nil), do: false
  defp cancel_tick_timer(ref), do: Process.cancel_timer(ref)
end
