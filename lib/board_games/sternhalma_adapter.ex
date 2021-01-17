defmodule BoardGames.SternhalmaAdapter do
  @moduledoc """
  Functions to help bridge the gap between
  Sternhalma library and this app.

  Goal is for this module to be the boundary
  between the external Sternhalma library and this
  Phoenix app.

  In retrospect, I'm not sure if the way I did this
  was helpful or not :)
  """

  alias BoardGames.{BoardLocation, Marble}

  @spec marbles_from_cells(list(BoardLocation.t()), String.t(), {String.t(), String.t()}) ::
          list(Marble.t())
  def marbles_from_cells(board, player_name, {bg_color, border_color}) do
    board
    |> Enum.filter(&(&1.occupied_by == player_name))
    |> Enum.map(fn board_location ->
      {x, y} = board_location.screen_position

      %Marble{
        id: Base.encode64(:crypto.strong_rand_bytes(10)),
        belongs_to: board_location.occupied_by,
        bg_color: bg_color,
        border_color: border_color,
        x: Float.round(x, 3),
        y: Float.round(y, 3)
      }
    end)
  end

  @spec setup_marbles(list(BoardLocation.t()), String.t()) ::
          {:ok, list(BoardLocation.t())} | {:error, atom()}
  def setup_marbles(board, player_name) do
    external_board =
      board
      |> to_external_board()

    with {:ok, board} <- Sternhalma.setup_marbles(external_board, player_name) do
      {:ok, from_external_board(board)}
    else
      {:error, :board_full} ->
        {:error, :board_full}
    end
  end

  @spec winner(list(BoardLocation.t())) :: String.t() | nil
  def winner(board) do
    board
    |> to_external_board()
    |> Sternhalma.winner()
  end

  @spec empty_board() :: list(BoardLocation.t())
  def empty_board() do
    Sternhalma.empty_board()
    |> from_external_board()
  end

  @spec find_path(list(BoardLocation.t()), BoardLocation.t(), BoardLocation.t()) ::
          list(BoardLocation.t())
  def find_path(board, start, finish) do
    start_cell = cell(start)
    finish_cell = cell(finish)

    board
    |> to_external_board()
    |> Sternhalma.find_path(start_cell, finish_cell)
    |> from_external_board()
  end

  @spec move_marble(list(BoardLocation.t()), String.t(), BoardLocation.t(), BoardLocation.t()) ::
          list(BoardLocation.t())
  def move_marble(board, player_name, start, finish) do
    start_cell = cell(start)
    finish_cell = cell(finish)

    board
    |> to_external_board()
    |> Sternhalma.move_marble(player_name, start_cell, finish_cell)
    |> from_external_board()
  end

  @spec board_position({number(), number()}) :: BoardLocation.grid_position()
  def board_position(screen_position) do
    grid_position = Sternhalma.from_pixel(screen_position)

    %{x: grid_position.x, y: grid_position.y, z: grid_position.z}
  end

  @spec screen_position(BoardLocation.grid_position()) :: {number(), number()}
  def screen_position(board_position) do
    hex =
      Sternhalma.Hex.new({
        board_position.x,
        board_position.z,
        board_position.y
      })

    Sternhalma.to_pixel(hex)
  end

  @spec from_external_board(Sternhalma.Board.t()) :: list(BoardLocation.t())
  defp from_external_board(board) do
    board
    |> Enum.map(fn cell ->
      screen_position = Sternhalma.to_pixel(cell.position)

      grid_position = %{
        x: cell.position.x,
        y: cell.position.y,
        z: cell.position.z
      }

      %BoardLocation{
        screen_position: screen_position,
        grid_position: grid_position,
        goal_for: cell.target,
        occupied_by: cell.marble
      }
    end)
  end

  @spec to_external_board(list(BoardLocation.t())) :: Sternhalma.Board.t()
  defp to_external_board(board) do
    Enum.map(board, fn board_location ->
      cell(board_location)
    end)
  end

  @spec cell(BoardLocation.t()) :: Sternhalma.Cell.t()
  defp cell(board_location) do
    %Sternhalma.Cell{
      position:
        Sternhalma.Hex.new({
          board_location.grid_position.x,
          board_location.grid_position.z,
          board_location.grid_position.y
        }),
      marble: board_location.occupied_by,
      target: board_location.goal_for
    }
  end
end
