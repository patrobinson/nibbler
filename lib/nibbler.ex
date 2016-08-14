defmodule Nibbler do
  use Application
  require Logger

  def start(_type, _args) do
    Application.get_env(:nibbler, :mode) |> start
  end

  def start(:agent) do
    import Supervisor.Spec, warn: false

    heartbeat_check = Application.get_env(:nibbler, :heartbeat_check)
    heartbeat_ttl = Application.get_env(:nibbler, :heartbeat_ttl)
    children = [
      worker(Discovery.Heartbeat, [heartbeat_check, heartbeat_ttl])
    ]

    opts = [strategy: :one_for_one, name: Nibbler.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start(:master) do
    {:ok, sup_pid} = Task.Supervisor.start_link(name: :task_supervisor)
    node_pattern = Application.get_env(:nibbler, :heartbeat_check)
    capture_arguments = [{"interface", ["en0"]}] # Example
    Discovery.select(node_pattern, "", fn
      {:ok, _} ->
        Task.Supervisor.start_child(:task_supervisor, Nibbler.Agent.SimpleLogger, :start_link, [capture_arguments])
      {:error, {:no_servers, _}} ->
        Logger.info "No hosts found"
    end)
    {:ok, sup_pid}
  end
end
