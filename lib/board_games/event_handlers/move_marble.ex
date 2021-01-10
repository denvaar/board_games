defmodule BoardGames.EventHandlers.MoveMarble do
  @moduledoc """
  Logic concerned with handling when a marble is moved
  from one position to another.
  """

  @spec handle({Cell.t(), Cell.t()}, GameState.t()) ::
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}}
  def handle({start, finish}, state) do
    move_marble(
      {start.marble == state.turn, start, finish},
      state
    )
  end

  @spec move_marble({boolean(), Cell.t(), Cell.t()}, GameState.t()) :: GameState.t()
  defp move_marble({true, start, finish}, state) do
    path = Sternhalma.find_path(state.board, start, finish)

    if !Enum.empty?(path) do
      board = Sternhalma.move_marble(state.board, start.marble, start, finish)

      [current_cell | remaining_path] = path

      timer_ref =
        Process.send_after(
          self(),
          {:advance_marble_along_path, current_cell.position, remaining_path},
          1
        )

      new_state = %{
        state
        | board: board,
          timer_ref: timer_ref,
          last_move: path
      }

      {:ok, new_state}
    else
      {:error, {:no_path, state}}
    end
  end

  defp move_marble({_, _, _}, state) do
    {:error, {:wrong_marble, state}}
  end
end
