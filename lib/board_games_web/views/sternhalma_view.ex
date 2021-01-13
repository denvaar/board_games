defmodule BoardGamesWeb.SternhalmaView do
  use BoardGamesWeb, :view

  @board_size 465
  @min_x -0.39230484541326227
  @max_x 20.392304845413264
  @max_x 23
  @min_y 0
  @max_y 27

  def player_styles(game, player) do
    bg_color = background_color(game.marble_colors, player)

    [
      "--bgc:#{bg_color}",
      "--bc:#{color(game.marble_colors, player)}"
    ]
    |> Enum.join(";")
  end

  def player_classes(game, player) do
    ["player-marble"]
    |> add_if(fn -> "highlight" end, game.turn == player)
    |> Enum.join(" ")
  end

  def marble_css_classes(is_turn, marble_owner, player_name, start, marble, last_path) do
    marble_position = Sternhalma.from_pixel({marble.x, marble.y})

    path_includes_marble? =
      last_path != nil and
        Enum.any?(last_path, fn path_cell -> path_cell.position == marble_position end)

    ["marble"]
    |> add_if(fn -> "clicked" end, is_turn and marble_owner == player_name and start == nil)
    |> add_if(fn -> "glow" end, start != nil and start.position == marble_position)
    |> add_if(fn -> "path" end, path_includes_marble?)
    |> Enum.join(" ")
  end

  def marble_styles(marble, players, player_name, last_path) do
    {left, bottom} =
      {marble.x, marble.y}
      |> normalize(@board_size, @min_x, @max_x, @min_y, @max_y)

    marble_position = Sternhalma.from_pixel({marble.x, marble.y})

    step_index = compute_step_index(last_path, marble_position)

    [
      "--left:#{left}px",
      "--bottom:#{bottom}px",
      "--bgc:#{marble.bg_color}",
      "--bc:#{marble.border_color}",
      "--rotation: #{rotate(players, player_name) * -1}deg",
      "color: #{text_color(marble.bg_color)}"
    ]
    |> add_if(fn -> "--path-step: \"#{step_index}\"" end, step_index != nil)
    |> Enum.join(";")
  end

  def board_cell_css_classes(is_turn, start, cell, last_path) do
    path_includes_cell? =
      last_path != nil and
        Enum.any?(last_path, fn path_cell -> path_cell.position == cell.position end)

    ["board-cell"]
    |> add_if(fn -> "clicked" end, is_turn and start != nil)
    |> add_if(fn -> "path" end, path_includes_cell?)
    |> Enum.join(" ")
  end

  def board_cell_styles(cell, players, player_name, last_path) do
    {left, bottom} =
      cell.position
      |> Sternhalma.to_pixel()
      |> normalize(@board_size, @min_x, @max_x, @min_y, @max_y)

    step_index =
      Enum.find_index(last_path, fn path_cell -> path_cell.position == cell.position end)

    [
      "--left:#{left}px",
      "--bottom:#{bottom}px",
      "--rotation: #{rotate(players, player_name) * -1}deg",
      "color: #ffffff"
    ]
    |> add_if(fn -> "--path-step: \"#{step_index + 1}\"" end, step_index != nil)
    |> Enum.join(";")
  end

  defp add_if(items, _item, false) do
    items
  end

  defp add_if(items, item, true) do
    [item.() | items]
  end

  defp compute_step_index(path, _marble_position) when path == nil or length(path) == 0, do: nil

  defp compute_step_index(path, marble_position) do
    final_position = List.last(path).position

    compute_step_index(final_position, marble_position, length(path))
  end

  defp compute_step_index(final_position, marble_position, path_length)
       when final_position == marble_position,
       do: path_length

  defp compute_step_index(_final_position, _marble_position, _path_length), do: nil

  defp text_color(<<"#", hex_color::binary>>) do
    with {:ok, <<red, green, blue>>} <- Base.decode16(hex_color, case: :mixed) do
      if red * 0.299 + green * 0.587 + blue * 0.114 > 186 do
        "#000000"
      else
        "#ffffff"
      end
    else
      _ ->
        # default to black
        "#000000"
    end
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

  defp normalize({x, y}, size, min_x, max_x, min_y, max_y) do
    # Fit 2d point within a box of a dimension represented by size

    # center
    x = x - (max_x - min_x) / 2
    y = y - (max_y - min_y) / 2

    # scale
    scale = max(max_x - min_x, max_y - min_y)
    x = x / scale * size + 12
    y = y / scale * size - 10

    x = round(x + size / 2)
    y = round(y + size / 2)

    {x, y}
  end
end
