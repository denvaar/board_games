defmodule BoardGamesWeb.SternhalmaView do
  use BoardGamesWeb, :view

  @board_size 485
  @min_x -0.39230484541326227
  @max_x 20.392304845413264
  @max_x 23
  @min_y 0
  @max_y 27

  def cell_classes(cell, last_path, start_cell, player_name, is_active) do
    classes =
      %{
        "glow" => start_cell != nil and start_cell.marble != nil and cell == start_cell,
        "path" =>
          last_path != nil and
            Enum.any?(last_path, fn path_cell -> path_cell.position == cell.position end),
        "active" =>
          is_active and
            ((cell.marble == player_name and start_cell == nil) or
               (cell.marble == nil and start_cell != nil))
      }
      |> Map.to_list()
      |> Enum.reduce("cell", fn {css_class, should_use?}, classes ->
        if should_use?, do: "#{classes} #{css_class}", else: classes
      end)
  end

  def cell_styles(cell, last_path, marble_colors, players, player_name) do
    {left, bottom} =
      cell.position
      |> Sternhalma.to_pixel()
      |> normalize(@board_size, @min_x, @max_x, @min_y, @max_y)

    {bg_color, border_color} = colors(marble_colors, cell.marble)

    step_index =
      Enum.find_index(last_path, fn path_cell -> path_cell.position == cell.position end)

    base_styles = [
      "--rotation: #{rotate(players, player_name) * -1}deg",
      "left: #{left}px",
      "bottom: #{bottom}px",
      "background-color: #{bg_color}",
      "border-color: #{border_color}"
    ]

    [
      {"--path-step: \"#{if step_index, do: step_index + 1}\"", step_index != nil},
      {"color: #{text_color(bg_color)}", step_index != nil}
    ]
    |> Enum.reduce(base_styles, fn {style, use?}, styles ->
      if use?, do: [style | styles], else: styles
    end)
    |> Enum.join(";")
  end

  defp colors(marble_colors, marble) do
    with {primary_color, secondary_color} <- Map.get(marble_colors, marble) do
      {primary_color, secondary_color}
    else
      nil ->
        {"#ffffff", "#999999"}
    end
  end

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

  defp luminance(_hex_color), do: "#000000"

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

    x = round(x + size / 2)
    y = round(y + size / 2)

    {x, y}
  end
end
