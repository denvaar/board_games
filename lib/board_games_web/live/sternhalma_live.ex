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
      end
    end

    {:ok, assign(socket, game: nil, game_id: game_id, player_name: player_name)}
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
  def handle_event("start-game", _params, socket) do
    with {:ok, game} <- GameState.start_game(socket.assigns.game_id) do
      broadcast_game_state_update!(socket.assigns.game_id, game)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "game_state_update", payload: game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  #
  # private functions
  #

  defp setup_live_view_process(game_id, player_name) do
    game_id
    |> monitor_live_view_process(player_name)
    |> ensure_game_process_exists()
    |> subscribe_to_updates()
    |> GameState.join_game(player_name)
  end

  defp topic(game_id) do
    "sternhalma:#{game_id}"
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
    game_id
    |> topic()
    |> BoardGamesWeb.Endpoint.subscribe()

    game_id
  end

  defp broadcast_game_state_update!(game_id, game) do
    game_id
    |> topic()
    |> BoardGamesWeb.Endpoint.broadcast!("game_state_update", game)
  end
end
