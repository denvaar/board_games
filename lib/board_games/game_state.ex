defmodule BoardGames.GameState do
  @moduledoc """
  Manage shared state for a game of Chinese Checkers.
  """

  use GenServer, restart: :transient

  @type game_status :: :setup | :playing | :over

  @type game_state :: %{
          game_id: binary(),
          board: Board.t(),
          turn: nil | String.t(),
          winner: nil | String.t(),
          last_move: list(Cell.t()),
          status: game_status(),
          players: list(String.t()),
          marble_colors: Map.t()
        }

  def start_link(game_id) do
    GenServer.start_link(
      __MODULE__,
      game_id,
      name: via(game_id)
    )
  end

  def join_game(game_id, player_name) do
    GenServer.call(via(game_id), {:join_game, player_name})
  end

  def leave_game(game_id, player_name) do
    GenServer.call(via(game_id), {:leave_game, player_name})
  end

  def start_game(game_id) do
    GenServer.call(via(game_id), {:set_status, :playing})
  end

  def move_marble(game_id, start, finish) do
    GenServer.call(via(game_id), {:move_marble, start, finish})
  end

  @impl true
  def init(game_id) do
    initial_state = %{
      id: game_id,
      board: Sternhalma.empty_board(),
      status: :setup,
      turn: nil,
      winner: nil,
      last_move: [],
      players: [],
      marble_colors: %{}
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:join_game, player_name}, _from, state) do
    # TODO: game must be in :setup status

    case Enum.find(state.players, &(&1 == player_name)) do
      nil ->
        {:ok, board} = Sternhalma.setup_marbles(state.board, player_name)

        new_state = %{
          state
          | board: board,
            players: [player_name | state.players],
            marble_colors: assign_color(player_name, state.marble_colors)
        }

        {:reply, {:ok, new_state}, new_state}

      existing_player ->
        {:reply, {:error, :player_exists, state}, state}
    end
  end

  def handle_call({:move_marble, start, finish}, _from, state) do
    if start.marble == state.turn do
      path = Sternhalma.find_path(state.board, start, finish)

      if !Enum.empty?(path) do
        board = Sternhalma.move_marble(state.board, start.marble, start, finish)
        winner = Sternhalma.winner(board)

        new_state = %{
          state
          | board: board,
            winner: winner,
            turn: next_turn(state.turn, state.players)
        }

        new_state =
          if winner != nil do
            with {:ok, state} <- change_game_status(new_state, :over) do
              state
            else
              _ ->
                new_state
            end
          else
            new_state
          end

        {:reply, {:ok, new_state}, new_state}
      else
        {:reply, {:error, :no_path}, state}
      end
    else
      {:reply, {:error, :wrong_marble}, state}
    end
  end

  def handle_call({:leave_game, player_name}, _from, state) do
    # TODO

    if state.status == :setup do
      new_state = %{state | players: Enum.reject(state.players, &(&1 == player_name))}
      {:reply, {:ok, new_state}, new_state}
    else
      {:reply, {:ok, state}, state}
    end
  end

  def handle_call({:set_status, status}, _from, state) do
    {result, new_state} =
      state
      |> change_game_status(status)
      |> perform_side_effects(status)

    {:reply, {result, new_state}, new_state}
  end

  # TODO consider moving these private functions to some other module

  @spec change_game_status(game_state(), game_status()) :: {:ok | :error, game_state()}
  defp change_game_status(game_state, :playing)
       when length(game_state.players) > 1 and game_state.status == :setup,
       do: {:ok, %{game_state | status: :playing}}

  defp change_game_status(game_state, :over) when game_state.status == :playing,
    do: {:ok, %{game_state | status: :over}}

  defp change_game_status(game_state, _), do: {:error, game_state}

  @spec perform_side_effects({:ok | :error, game_state()}, game_status()) ::
          {:ok | :error, game_state()}
  defp perform_side_effects({:ok, game_state}, :playing) do
    {:ok, %{game_state | turn: List.first(game_state.players)}}
  end

  defp perform_side_effects({:ok, game_state}, _), do: {:ok, game_state}
  defp perform_side_effects({:error, game_state}, _), do: {:error, game_state}

  defp via(game_id) do
    {:via, Registry, {:game_registry, game_id}}
  end

  @spec next_turn(String.t(), list(String.t())) :: String.t()
  defp next_turn(turn, players) do
    next_player_index =
      case Enum.find_index(players, &(&1 == turn)) do
        nil ->
          0

        current_player_index ->
          rem(current_player_index + 1, length(players))
      end

    Enum.at(players, next_player_index)
  end

  @spec assign_color(String.t(), Map.t()) :: Map.t()
  defp assign_color(player_name, marble_colors) do
    with [first_available_color | _] <-
           marble_colors
           |> Map.values()
           |> BoardGames.MarbleColors.available_colors() do
      Map.put(marble_colors, player_name, first_available_color)
    else
      _ ->
        marble_colors
    end
  end
end
