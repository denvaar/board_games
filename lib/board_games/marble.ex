defmodule BoardGames.Marble do
  @moduledoc """
  Struct to represent a marble.
  """

  alias __MODULE__

  @enforce_keys [:id, :belongs_to, :bg_color, :border_color, :x, :y]
  defstruct @enforce_keys

  @type t :: %Marble{
          id: String.t(),
          belongs_to: String.t(),
          bg_color: String.t(),
          border_color: String.t(),
          x: float(),
          y: float()
        }
end
