defmodule BoardGames.SternhalmaAdapter do
  @moduledoc """
  Functions to help bridge the gap between
  Sternhalma library and this app.

  Goal is for this module to be the boundary
  between the external Sternhalma library and this
  Phoenix app.
  """

  alias Sternhalma.Board

  alias BoardGames.Marble

  @spec marbles_from_cells(Board.t(), String.t(), {String.t(), String.t()}) ::
          list(Marble.t())
  def marbles_from_cells(board, player_name, {bg_color, border_color}) do
    board
    |> Enum.filter(&(&1.marble == player_name))
    |> Enum.map(fn cell ->
      {x, y} = Sternhalma.to_pixel(cell.position)

      %Marble{
        id: Base.encode64(:crypto.strong_rand_bytes(10)),
        belongs_to: cell.marble,
        bg_color: bg_color,
        border_color: border_color,
        x: Float.round(x, 3),
        y: Float.round(y, 3)
      }
    end)
  end

  @spec setup_marbles(Board.t(), String.t()) :: {:ok, Board.t()} | {:error, :board_full}
  defdelegate setup_marbles(board, player_name), to: Sternhalma

  @spec winner(Board.t()) :: String.t() | nil
  defdelegate winner(board), to: Sternhalma
end
