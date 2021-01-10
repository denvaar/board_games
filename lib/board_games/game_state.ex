defmodule BoardGames.GameState do
  @moduledoc """
  Manage shared state for a game of Chinese Checkers.
  """

  use GenServer, restart: :transient

  alias BoardGames.{Marble, EventHandlers}

  @type game_status :: :setup | :playing | :over

  @type game_state :: %{
          game_id: binary(),
          board: Board.t(),
          marbles: list(Marble.t()),
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
      marbles: [],
      status: :setup,
      turn: nil,
      timer_ref: nil,
      winner: nil,
      last_move: [],
      players: [],
      marble_colors: %{}
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:join_game, player_name}, _from, state) do
    with {:ok, new_state} <- EventHandlers.JoinGame.handle({player_name}, state) do
      {:reply, {:ok, new_state}, new_state}
    else
      {:error, {code, state}} ->
        {:reply, {:error, code, state}, state}
    end
  end

  def handle_call({:move_marble, start, finish}, _from, state) do
    with {:ok, new_state} <- EventHandlers.MoveMarble.handle({start, finish}, state) do
      {:reply, {:ok, new_state}, new_state}
    else
      {:error, {code, state}} ->
        {:reply, {:error, code, state}, state}
    end
  end

  def handle_call({:leave_game, player_name}, _from, state) do
    with {:ok, new_state} <- EventHandlers.LeaveGame.handle({player_name}, state) do
      {:reply, {:ok, new_state}, new_state}
    else
      {:error, {code, state}} ->
        {:reply, {:error, code, state}, state}
    end
  end

  def handle_call({:set_status, status}, _from, state) do
    with {:ok, new_state} <- EventHandlers.StatusChange.handle({status}, state) do
      {:reply, {:ok, new_state}, new_state}
    else
      {:error, {code, state}} ->
        {:reply, {:error, code, state}, state}
    end
  end

  @impl true
  def handle_info({:advance_marble_along_path, current_position, []}, state) do
    {:ok, new_state} =
      EventHandlers.AdvanceMarble.handle(
        {current_position, []},
        state
      )

    {:noreply, new_state}
  end

  def handle_info({:advance_marble_along_path, current_position, path}, state) do
    {:ok, new_state} =
      EventHandlers.AdvanceMarble.handle(
        {current_position, path},
        state
      )

    {:noreply, new_state}
  end

  defp via(game_id) do
    {:via, Registry, {:game_registry, game_id}}
  end
end
