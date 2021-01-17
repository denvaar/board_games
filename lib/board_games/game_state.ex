defmodule BoardGames.GameState do
  @moduledoc """
  Defines a struct to hold the game state used throughout the app.
  """

  alias BoardGames.{BoardLocation, SternhalmaAdapter, Marble}

  @type game_status :: :setup | :playing | :over

  @type t :: %__MODULE__{
          board: list(BoardLocation.t()),
          id: binary(),
          last_move: list(BoardLocation.t()),
          marble_colors: map(),
          marbles: list(Marble.t()),
          players: list(String.t()),
          seconds_remaining: non_neg_integer(),
          status: game_status(),
          timer_ref: nil | reference(),
          turn: nil | String.t(),
          turn_timer_ref: nil | reference(),
          winner: nil | String.t()
        }

  @enforce_keys [:id]
  defstruct [
    :id,
    board: SternhalmaAdapter.empty_board(),
    last_move: [],
    marble_colors: %{},
    marbles: [],
    players: [],
    seconds_remaining: 0,
    status: :setup,
    timer_ref: nil,
    turn: nil,
    turn_timer_ref: nil,
    winner: nil
  ]
end
