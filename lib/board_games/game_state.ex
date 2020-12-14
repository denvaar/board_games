defmodule BoardGames.GameState do
  @moduledoc """
  Manage shared state for a game of Chinese Checkers.
  """

  alias Sternhalma.{Board, Cell}

  use GenServer, restart: :transient

  @type game_status :: :setup | :playing | :over

  @type game_state :: %{
          game_id: binary(),
          board: Board.t(),
          turn: nil | String.t(),
          last_move: list(Cell.t()),
          status: game_status(),
          players: list(String.t())
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

  @impl true
  def init(game_id) do
    initial_state = %{
      id: game_id,
      board: Board.empty(),
      status: :setup,
      turn: nil,
      last_move: [],
      players: []
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:join_game, player_name}, _from, state) do
    # new_state = %{state | players: [player_name | state.players]}
    new_state = add_player_impl(state, player_name)

    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:leave_game, player_name}, _from, state) do
    new_state = %{state | players: Enum.filter(state.players, &(&1 != player_name))}

    {:reply, {:ok, new_state}, new_state}
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

  @spec add_player_impl(game_state(), String.t()) :: game_state()
  defp add_player_impl(game_state, player_name) do
    number_of_existing_players = length(game_state.players)

    %{
      game_state
      | players: [player_name | game_state.players],
        board:
          Board.setup_triangle(
            game_state.board,
            position_opponent(number_of_existing_players),
            player_name
          )
    }
  end

  @spec position_opponent(0..5) :: Board.home_triangle()
  defp position_opponent(0), do: :top
  defp position_opponent(1), do: :bottom
  defp position_opponent(2), do: :top_left
  defp position_opponent(3), do: :bottom_right
  defp position_opponent(4), do: :top_right
  defp position_opponent(5), do: :bottom_left

  defp via(game_id) do
    {:via, Registry, {:game_registry, game_id}}
  end
end
