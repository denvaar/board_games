defmodule BoardGames.GameServer do
  @moduledoc """
  GenServer implementation which is used to interact
  with `BoardGames.GameState`. This module provides a
  client API to carry out a game of Chinese Checkers.
  """

  use GenServer, restart: :transient

  alias BoardGames.{GameState, Helpers, EventHandlers}

  @time_limit_seconds 10

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(game_id) do
    GenServer.start_link(
      __MODULE__,
      game_id,
      name: via(game_id)
    )
  end

  @doc """
  Add a player to a game.

  See `BoardGames.EventHandlers.JoinGame` for details of what is involved in this.
  """
  @spec join_game(String.t(), String.t()) :: term()
  def join_game(game_id, player_name) do
    GenServer.call(via(game_id), {:join_game, player_name})
  end

  @doc """
  Remove a player from a game.

  See `BoardGames.EventHandlers.LeaveGame` for details of what is involved in this.
  """
  @spec leave_game(String.t(), String.t()) :: term()
  def leave_game(game_id, player_name) do
    GenServer.call(via(game_id), {:leave_game, player_name})
  end

  @doc """
  Change the status of a game from `:setup` to `:playing`.
  """
  @spec start_game(String.t()) :: term()
  def start_game(game_id) do
    GenServer.call(via(game_id), {:set_status, :playing})
  end

  @doc """
  Move from `start` cell to `finish` cell if possible.

  See `BoardGames.EventHandlers.MoveMarble` for details of what is involved in this.
  """
  @spec move_marble(String.t(), Sternhalma.Cell.t(), Sternhalma.Cell.t()) :: term()
  def move_marble(game_id, start, finish) do
    GenServer.call(via(game_id), {:move_marble, start, finish})
  end

  # @spec init(String.t()) :: {:ok, GameState.t()}
  @impl true
  def init(game_id) do
    {:ok, %GameState{id: game_id}}
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
  def handle_info({:advance_marble_along_path, current_position, path}, state) do
    {:ok, new_state} =
      EventHandlers.AdvanceMarble.handle(
        {current_position, path},
        state
      )

    {:noreply, new_state}
  end

  def handle_info({:tick, seconds_elapsed, :keep_turn}, state) do
    new_state = tick(seconds_elapsed, state)

    BoardGames.PubSub.broadcast_game_update!(state.id, new_state)

    {:noreply, new_state}
  end

  def handle_info({:tick, seconds_elapsed, _}, state) do
    new_state = tick(seconds_elapsed, state)

    turn =
      if new_state.seconds_remaining == 0,
        do: Helpers.next_turn(state.turn, state.players),
        else: state.turn

    new_state = %{new_state | turn: turn}

    BoardGames.PubSub.broadcast_game_update!(state.id, new_state)

    {:noreply, new_state}
  end

  @spec tick(non_neg_integer(), GameState.t()) :: GameState.t()
  defp tick(seconds_elapsed, state) do
    seconds = rem(seconds_elapsed + 1, @time_limit_seconds)

    ref =
      Process.send_after(
        self(),
        {:tick, seconds, nil},
        1_000
      )

    %{state | turn_timer_ref: ref, seconds_remaining: seconds}
  end

  @spec via(String.t()) :: {:via, module(), {atom(), String.t()}}
  defp via(game_id) do
    {:via, Registry, {:game_registry, game_id}}
  end
end
