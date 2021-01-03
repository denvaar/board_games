defmodule LobbyComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    BoardGamesWeb.SternhalmaView.render("scoreboard.html", assigns)
  end
end
