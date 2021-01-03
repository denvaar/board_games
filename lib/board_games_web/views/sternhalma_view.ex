defmodule BoardGamesWeb.SternhalmaView do
  use BoardGamesWeb, :view

  @board_size 380
  @min_x -0.39230484541326227
  @max_x 20.392304845413264
  @min_y 1
  @max_y 25

  def positions(board, marble_colors, start_cell) do
    board
    |> Enum.map(fn cell ->
      pos =
        cell.position
        |> Sternhalma.to_pixel()
        |> normalize(@board_size, @min_x, @max_x, @min_y, @max_y)

      with {primary_color, secondary_color} <- Map.get(marble_colors, cell.marble) do
        {pos, primary_color, secondary_color, start_cell != nil and cell == start_cell}
      else
        nil ->
          {pos, "#ffffff", "#999999", false}
      end
    end)
    |> Enum.with_index()
  end

  @spec rotate(list(String.t()), String.t()) :: non_neg_integer()
  def rotate(players, player_name) do
    players
    |> Enum.reverse()
    |> Enum.find_index(&(&1 == player_name))
    |> rotation()
  end

  defp rotation(0), do: 180
  defp rotation(1), do: 0
  defp rotation(2), do: 240
  defp rotation(3), do: 60
  defp rotation(4), do: 120
  defp rotation(5), do: 300
  defp rotation(_player_index), do: 0

  def background_color(colors, player_name) do
    color_helper(colors, player_name)
    |> Enum.at(0)
  end

  def color(colors, player_name) do
    color_helper(colors, player_name)
    |> Enum.at(1)
  end

  defp color_helper(colors, player_name) do
    colors
    |> Map.get(player_name)
    |> Tuple.to_list()
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
