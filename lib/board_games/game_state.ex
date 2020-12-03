defmodule BoardGames.GameState do
  @moduledoc """
  Manage shared state for a game of Chinese Checkers.
  """

  use GenServer, restart: :transient

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

  @impl true
  def init(game_id) do
    {:ok, %{id: game_id, players: []}}
  end

  @impl true
  def handle_call({:join_game, player_name}, _from, state) do
    new_state = %{state | players: [player_name | state.players]}

    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:leave_game, player_name}, _from, state) do
    new_state = %{state | players: Enum.filter(state.players, &(&1 != player_name))}

    {:reply, {:ok, new_state}, new_state}
  end

  defp via(game_id) do
    {:via, Registry, {:game_registry, game_id}}
  end
end
