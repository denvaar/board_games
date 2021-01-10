defmodule BoardGames.SternhalmaAdapter do
  @moduledoc """
  Functions to help bridge the gap between
  Sternhalma library and this app.
  """

  alias BoardGames.Marble

  def marbles_from_cells(board, player_name, {bg_color, border_color}) do
    board
    |> Enum.filter(&(&1.marble == player_name))
    |> Enum.map(fn cell ->
      {x, y} = Sternhalma.to_pixel(cell.position)

      %Marble{
        id: Base.encode64(:crypto.strong_rand_bytes(15)),
        belongs_to: cell.marble,
        bg_color: bg_color,
        border_color: border_color,
        x: Float.round(x, 3),
        y: Float.round(y, 3)
      }
    end)
  end

  defdelegate setup_marbles(board, player_name), to: Sternhalma
end
