defmodule BoardGames.LiveMonitor do
  @moduledoc """
  A GenServer that keeps track of LiveView processes.

  Monitors processes and invokes `unmount` when
  they go down.
  """

  use GenServer

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @doc """
  Monitor the given process, identified by `pid`, `view_module`, along with any metadata.

  This GenServer process will receive a `:DOWN` message whenever the process exits.

  A function, `unmount`, is expected to be implemented on the `view_module`.
  """
  @spec monitor(pid(), module(), map()) :: term()
  def monitor(pid, view_module, meta) do
    GenServer.call(__MODULE__, {:monitor, pid, view_module, meta})
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  def handle_call({:monitor, pid, view_module, meta}, _, %{views: views} = state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, meta})}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    {{module, meta}, new_views} = Map.pop(state.views, pid)
    spawn(fn -> module.unmount(reason, meta) end)
    {:noreply, %{state | views: new_views}}
  end
end
