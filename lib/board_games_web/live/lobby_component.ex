defmodule LobbyComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <h3>Players</h3>
    <ul>
      <%= for player <- @players do %>
        <li><%= player %></li>
      <% end %>
    </ul>

    <%= if length(@players) > 1 do %>
      <button phx-click="start-game">Start game</button>
    <% end %>
    """
  end
end
