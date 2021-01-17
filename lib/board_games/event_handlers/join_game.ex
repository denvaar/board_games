defmodule BoardGames.EventHandlers.JoinGame do
  @moduledoc """
  Logic concerned with updating game state in
  response to a new player joining.
  """

  alias BoardGames.{SternhalmaAdapter, GameState, MarbleColors}

  defmodule IncomingPlayerInfo do
    @enforce_keys [:id, :exists_already]
    defstruct [:id, :exists_already]

    @type t :: %IncomingPlayerInfo{
            id: String.t(),
            exists_already: boolean()
          }
  end

  @spec handle({String.t()}, GameState.t()) ::
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}}
  def handle({player_name}, state) do
    exists_already = !!Enum.find(existing_players(state.players), &(&1 == player_name))

    %IncomingPlayerInfo{id: player_name, exists_already: exists_already}
    |> add_player_to_game(state.status, state)
  end

  @spec add_player_to_game(IncomingPlayerInfo.t(), GameState.game_status(), GameState.t()) ::
          {:ok, GameState.t()} | {:error, {atom(), GameState.t()}}
  defp add_player_to_game(
         %IncomingPlayerInfo{id: player_name, exists_already: false},
         :setup,
         state
       ) do
    with {:ok, board} <- SternhalmaAdapter.setup_marbles(state.board, player_name) do
      marble_colors = assign_color(player_name, state.marble_colors)

      default_colors = {"#000000", "#000000"}
      colors = Map.get(marble_colors, player_name, default_colors)

      marbles =
        SternhalmaAdapter.marbles_from_cells(
          board,
          player_name,
          colors
        )

      new_state = %{
        state
        | board: board,
          marbles: marbles ++ state.marbles,
          players: [player_name | state.players],
          connected_players: [player_name | state.connected_players],
          marble_colors: marble_colors
      }

      {:ok, new_state}
    else
      {:error, :board_full} ->
        {:error, {:board_full, state}}
    end
  end

  defp add_player_to_game(incoming_player_info, _, state) do
    {:error,
     {:game_in_progress,
      %{state | connected_players: [incoming_player_info.id | state.connected_players]}}}
  end

  @spec existing_players(list(String.t())) :: list(String.t())
  defp existing_players([_ | _] = existing_players), do: existing_players
  defp existing_players(_), do: []

  @spec assign_color(String.t(), map()) :: map()
  defp assign_color(player_name, marble_colors) do
    with [first_available_color | _] <-
           marble_colors
           |> Map.values()
           |> MarbleColors.available_colors() do
      Map.put(marble_colors, player_name, first_available_color)
    else
      _ ->
        marble_colors
    end
  end
end
