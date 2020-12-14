defmodule GameBoardComponent do
  use Phoenix.LiveComponent

  @board_size 380
  @min_x -0.39230484541326227
  @max_x 20.392304845413264
  @min_y 1
  @max_y 25

  @mapping %{"denver" => "#6292e9", "niccole" => "#44ae64"}
  @border_mapping %{"denver" => "#3864b3", "niccole" => "#308249"}

  def render(assigns) do
    positions =
      assigns.board
      |> Enum.map(fn cell ->
        pos =
          cell.position
          |> Sternhalma.Hex.to_pixel()
          |> normalize(@board_size, @min_x, @max_x, @min_y, @max_y)

        {pos, color_for_marble(cell.marble, @mapping), border_color(cell.marble, @border_mapping)}
      end)

    thing =
      assigns.board
      |> Enum.map(fn c ->
        {x, y} =
          c.position
          |> Sternhalma.Hex.to_pixel()

        # |> normalize(@board_size, @min_x, @max_x, @min_y, @max_y)

        "(#{x}, #{y}),"
      end)
      |> List.to_string()

    ~L"""
    <p><%= thing %></p>
    <div class="board-container">
      <%= for {{x, y}, marble_color, border_color} <- positions do %>
        <div
          class="cell"
          style="left:<%= x %>px;bottom:<%= y %>px;background-color:<%= marble_color %>;border-color:<%= border_color %>;"></div>
      <% end %>
    </div>
    """
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

  defp color_for_marble(nil, _mapping), do: "white"
  defp color_for_marble(marble, mapping), do: Map.get(mapping, marble)

  defp border_color(nil, _mapping), do: "#999"
  defp border_color(marble, mapping), do: Map.get(mapping, marble)
end
