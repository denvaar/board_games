defmodule BoardGames.MarbleColors do
  @primary_blue "#6292e9"
  @primary_green "#44ae64"
  @primary_orange "#f3734b"
  @primary_black "#545454"
  @primary_purple "#9a7abd"
  @primary_red "#f93f62"

  @secondary_blue "#3864b3"
  @secondary_green "#308249"
  @secondary_orange "#c35330"
  @secondary_black "#000000"
  @secondary_purple "#573e84"
  @secondary_red "#9e3458"

  def all_colors() do
    [
      Blue: @primary_blue,
      Green: @primary_green,
      Orange: @primary_orange,
      Black: @primary_black,
      Purple: @primary_purple,
      Red: @primary_red
    ]
  end

  @spec available_colors(list({String.t(), String.t()})) :: list({String.t(), String.t()})
  def available_colors(to_be_excluded) do
    [
      {@primary_blue, @secondary_blue},
      {@primary_green, @secondary_green},
      {@primary_orange, @secondary_orange},
      {@primary_black, @secondary_black},
      {@primary_purple, @secondary_purple},
      {@primary_red, @secondary_red}
    ] --
      to_be_excluded
  end

  def all_secondary_colors() do
    [
      @secondary_blue,
      @secondary_green,
      @secondary_orange,
      @secondary_black,
      @secondary_purple,
      @secondary_red
    ]
  end
end
