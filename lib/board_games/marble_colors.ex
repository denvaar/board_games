defmodule BoardGames.MarbleColors do
  @moduledoc """
  Module to define color constants for the marbles.

  Marbles have a primary color, used for the background.
  Also a secondary color, used for the boarder.
  """

  @primary_blue "#6292e9"
  @primary_green "#44ae64"
  @primary_orange "#f3734b"
  @primary_gold "#ffe389"
  @primary_purple "#9a7abd"
  @primary_red "#f93f62"

  @secondary_blue "#3864b3"
  @secondary_green "#308249"
  @secondary_orange "#c35330"
  @secondary_gold "#be9e2d"
  @secondary_purple "#573e84"
  @secondary_red "#9e3458"

  @spec available_colors(list({String.t(), String.t()})) :: list({String.t(), String.t()})
  def available_colors(to_be_excluded) do
    [
      {@primary_blue, @secondary_blue},
      {@primary_green, @secondary_green},
      {@primary_orange, @secondary_orange},
      {@primary_gold, @secondary_gold},
      {@primary_purple, @secondary_purple},
      {@primary_red, @secondary_red}
    ] --
      to_be_excluded
  end
end
