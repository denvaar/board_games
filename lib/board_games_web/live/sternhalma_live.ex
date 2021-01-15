defmodule BoardGamesWeb.SternhalmaLive do
  use BoardGamesWeb, :live_view

  alias BoardGames.{GameSupervisor, LiveMonitor, GameState}

  @impl true
  def mount(_params, session, socket) do
    game_id = Map.get(session, "game_id")
    player_name = Map.get(session, "player_name")

    if connected?(socket) do
      with {:ok, game} <- setup_live_view_process(game_id, player_name) do
        broadcast_game_state_update!(game_id, game)
      else
        {:error, code, game} ->
          IO.inspect(code)
          broadcast_game_state_update!(game_id, game)
      end
    end

    {:ok,
     assign(socket,
       game: nil,
       game_id: game_id,
       message: nil,
       player_name: player_name,
       start: nil
     )}
  end

  def unmount(_reason, %{player_id: player_id, game_id: game_id}) do
    {:ok, game} = GameState.leave_game(game_id, player_id)
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
    with {:ok, game} <- GameState.start_game(socket.assigns.game_id) do
      broadcast_game_state_update!(socket.assigns.game_id, game)
    end

    {:noreply, socket}
  end

  def handle_event("marble-click", %{"marble_id" => marble_id}, socket) do
    marble =
      socket.assigns.game.marbles
      |> Enum.find(&(&1.id === marble_id))

    cell =
      socket.assigns.game.board
      |> Enum.find(&(&1.position == Sternhalma.from_pixel({marble.x, marble.y})))

    start = Map.get(socket.assigns, :start)

    if start do
      with {:ok, game} <- GameState.move_marble(socket.assigns.game_id, start, cell) do
        broadcast_game_state_update!(socket.assigns.game_id, game)
      else
        e ->
          IO.inspect(e)
      end

      {:noreply, assign(socket, start: nil)}
    else
      {:noreply, assign(socket, start: cell)}
    end
  end

  def handle_event("board-cell-click", %{"idx" => index}, socket) do
    cell =
      socket.assigns.game.board
      |> Enum.at(String.to_integer(index))

    start = Map.get(socket.assigns, :start)

    if start do
      message =
        with {:ok, game} <- GameState.move_marble(socket.assigns.game_id, start, cell) do
          broadcast_game_state_update!(socket.assigns.game_id, game)
          nil
        else
          {:error, code, _state} ->
            message_for_code(code)
        end

      {:noreply, assign(socket, start: nil, message: message)}
    else
      {:noreply, assign(socket, start: cell)}
    end
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

  defp setup_live_view_process(game_id, player_name) do
    game_id
    |> monitor_live_view_process(player_name)
    |> ensure_game_process_exists()
    |> subscribe_to_updates()
    |> ensure_player_joins(player_name)
  end

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

  defp ensure_game_process_exists({:ok, game_id}) do
    case GameSupervisor.start_child({GameState, game_id}) do
      {:ok, _pid} -> {:ok, game_id}
      {:error, {:already_started, _pid}} -> {:ok, game_id}
      _ -> {:error, game_id}
    end
  end

  defp subscribe_to_updates({:ok, game_id}) do
    BoardGames.PubSub.subscribe_to_game_updates(game_id)
    game_id
  end

  defp ensure_player_joins(game_id, player_name) do
    game_id
    |> GameState.join_game(player_name)
  end

  defp broadcast_game_state_update!(game_id, game) do
    BoardGames.PubSub.broadcast_game_update!(game_id, game)
  end

  defp message_for_code(:no_path), do: "Cannot move there."
  defp message_for_code(_), do: "??? wat"

  defp update_marble_selection(0, selection_start), do: nil
  defp update_marble_selection(_seconds_remaining, selection_start), do: selection_start
end
