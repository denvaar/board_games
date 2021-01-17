defmodule BoardGames.BoardLocation do
  @enforce_keys [:screen_position, :grid_position]
  defstruct @enforce_keys ++ [:goal_for, :occupied_by]

  @type grid_position :: %{
          x: number(),
          y: number(),
          z: number()
        }

  @type t :: %__MODULE__{
          goal_for: String.t() | nil,
          screen_position: {number(), number()},
          grid_position: grid_position(),
          occupied_by: String.t() | nil
        }
end
