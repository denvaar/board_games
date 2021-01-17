defmodule BoardGamesWeb.SternhalmaLive do
  @moduledoc """
  Module to allow players to play Chinese Checkers from a browser.

  LiveView processes are created as users join a game.

  Events are sent to LiveView processes as players interact with the page.

  The shared game state is updated and changed as events are handled.

  As result of most interactions, the game state is broadcast to all
  other connected players in the game room.
  """

  use BoardGamesWeb, :live_view

  alias BoardGames.{
    GameSupervisor,
    LiveMonitor,
    GameServer,
    SternhalmaAdapter,
    BoardLocation,
    GameState
  }

  @impl true
  def mount(_params, session, socket) do
    game_id = Map.get(session, "game_id")
    player_name = Map.get(session, "player_name")

    message =
      if connected?(socket) do
        with {:ok, game} <- setup_live_view_process(game_id, player_name) do
          broadcast_game_state_update!(game_id, game)
          nil
        else
          {:error, code, game} ->
            broadcast_game_state_update!(game_id, game)
            message_for_code(code)
        end
      end

    {:ok,
     assign(socket,
       game: nil,
       game_id: game_id,
       message: message,
       player_name: player_name,
       start: nil
     )}
  end

  @doc """
  Callback that happens when the LV process is terminating.

  This allows the player to be removed from the game, and
  the entire game server process can also be terminated if
  there are no remaining players.
  """
  @spec unmount(term(), map()) :: :ok
  def unmount(_reason, %{player_id: player_id, game_id: game_id}) do
    {:ok, game} = GameServer.leave_game(game_id, player_id)
    broadcast_game_state_update!(game_id, game)

    if length(game.players) <= 0 do
      GameSupervisor.terminate_child(game_id)
    end

    :ok
  end

  @impl true
  def render(assigns) do
    BoardGamesWeb.SternhalmaView.render("sternhalma_live.html", assigns)
  end

  @impl true
  def handle_event("start-game", _params, socket) do
    with {:ok, game} <- GameServer.start_game(socket.assigns.game_id) do
      broadcast_game_state_update!(socket.assigns.game_id, game)
    end

    {:noreply, socket}
  end

  def handle_event("marble-click", %{"marble_id" => marble_id}, socket) do
    marble =
      socket.assigns.game.marbles
      |> Enum.find(&(&1.id === marble_id))

    marble_grid_position = SternhalmaAdapter.board_position({marble.x, marble.y})

    cell =
      Enum.find(socket.assigns.game.board, fn location ->
        location.grid_position == marble_grid_position
      end)

    {:noreply, assign(socket, start: cell)}
  end

  def handle_event("board-cell-click", %{"x" => x, "y" => y, "z" => z}, socket)
      when socket.assigns.start != nil do
    start = Map.get(socket.assigns, :start)

    board_location =
      Enum.find(socket.assigns.game.board, fn location ->
        location.grid_position == %{
          x: String.to_integer(x),
          y: String.to_integer(y),
          z: String.to_integer(z)
        }
      end)

    message =
      with {:ok, game} <- GameServer.move_marble(socket.assigns.game_id, start, board_location) do
        broadcast_game_state_update!(socket.assigns.game_id, game)
        nil
      else
        {:error, code, _state} ->
          message_for_code(code)
      end

    {:noreply, assign(socket, start: nil, message: message)}
  end

  def handle_event("board-cell-click", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "game_state_update", payload: game}, socket) do
    {:noreply,
     assign(socket,
       game: game,
       start: update_marble_selection(game.seconds_remaining, socket.assigns.start)
     )}
  end

  #
  # private functions
  #

  @spec setup_live_view_process(String.t(), String.t()) ::
          {:ok, GameState.t()} | {:error, atom(), GameState.t()}
  defp setup_live_view_process(game_id, player_name) do
    game_id
    |> monitor_live_view_process(player_name)
    |> ensure_game_process_exists()
    |> subscribe_to_updates()
    |> ensure_player_joins(player_name)
  end

  @spec monitor_live_view_process(String.t(), String.t()) :: term()
  defp monitor_live_view_process(game_id, player_name) do
    with :ok <-
           LiveMonitor.monitor(
             self(),
             __MODULE__,
             %{player_id: player_name, game_id: game_id}
           ) do
      {:ok, game_id}
    end
  end

  @spec ensure_game_process_exists({:ok, String.t()}) :: {:ok | :error, String.t()}
  defp ensure_game_process_exists({:ok, game_id}) do
    case GameSupervisor.start_child({GameServer, game_id}) do
      {:ok, _pid} -> {:ok, game_id}
      {:error, {:already_started, _pid}} -> {:ok, game_id}
      _ -> {:error, game_id}
    end
  end

  @spec subscribe_to_updates({:ok, String.t()}) :: String.t()
  defp subscribe_to_updates({:ok, game_id}) do
    BoardGames.PubSub.subscribe_to_game_updates(game_id)
    game_id
  end

  @spec ensure_player_joins(String.t(), String.t()) ::
          {:ok, GameState.t()} | {:error, atom(), GameState.t()}
  defp ensure_player_joins(game_id, player_name) do
    game_id
    |> GameServer.join_game(player_name)
  end

  @spec broadcast_game_state_update!(String.t(), GameState.t()) :: :ok
  defp broadcast_game_state_update!(game_id, game) do
    BoardGames.PubSub.broadcast_game_update!(game_id, game)
  end

  @spec message_for_code(atom()) :: String.t()
  defp message_for_code(:no_path), do: "Cannot move there."
  defp message_for_code(:game_in_progress), do: "Game is in progress."
  defp message_for_code(_), do: "??? wat"

  @spec update_marble_selection(non_neg_integer(), BoardLocation.t()) ::
          nil | BoardLocation.t()
  defp update_marble_selection(0, _selection_start), do: nil
  defp update_marble_selection(_seconds_remaining, selection_start), do: selection_start
end
