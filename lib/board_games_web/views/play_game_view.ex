defmodule BoardGamesWeb.PlayGameView do
  use BoardGamesWeb, :view

  @board_size 380
  @min_x -0.39230484541326227
  @max_x 20.392304845413264
  @min_y 1
  @max_y 25

  def positions(board, marble_colors) do
    board
    |> Enum.map(fn cell ->
      pos =
        cell.position
        |> Sternhalma.to_pixel()
        |> normalize(@board_size, @min_x, @max_x, @min_y, @max_y)

      with {primary_color, secondary_color} <- Map.get(marble_colors, cell.marble) do
        {pos, primary_color, secondary_color}
      else
        nil ->
          {pos, "#ffffff", "#999999"}
      end
    end)
  end

  @doc """
  Fit 2d point within a box of a dimension represented by size
  """
  defp normalize({x, y}, size, min_x, max_x, min_y, max_y) do
    # center
    x = x - (max_x - min_x) / 2
    y = y - (max_y - min_y) / 2

    # scale
    scale = max(max_x - min_x, max_y - min_y)
    x = x / scale * size
    y = y / scale * size

    x = x + size / 2
    y = y + size / 2

    {x, y}
  end
end
