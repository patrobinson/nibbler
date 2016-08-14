defmodule Nibbler do
  use Application
  require Logger

  def start(_type, _args) do
    Application.get_env(:nibbler, :cookie) |> Node.set_cookie
    Application.get_env(:nibbler, :mode) |> start
  end

  def start(:agent) do
    import Supervisor.Spec, warn: false

    Task.Supervisor.start_link(name: Nibbler.Agent.TaskSupervisor)

    heartbeat_check = Application.get_env(:nibbler, :heartbeat_check)
    heartbeat_ttl = Application.get_env(:nibbler, :heartbeat_ttl)
    children = [
      worker(Discovery.Heartbeat, [heartbeat_check, heartbeat_ttl])
    ]

    opts = [strategy: :one_for_one, name: Nibbler.Agent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start(:master) do
    import Supervisor.Spec, warn: false

    node_pattern = Application.get_env(:nibbler, :heartbeat_check) |> String.split(":") |> List.last
    children = [
      worker(Discovery.Poller, [node_pattern, Discovery.Handler.NodeConnect], id: Nibbler.Master.MyPoller),
    ]
    opts = [strategy: :one_for_one, name: Nibbler.Master.Supervisor]
    {:ok, sup_pid} = Supervisor.start_link(children, opts)
    capture_arguments = [{"interface", ["en0"]}] # Example
    for node <- Discovery.nodes(node_pattern) do
      Task.Supervisor.async(
        {Nibbler.Agent.TaskSupervisor, node},
        fn -> Nibbler.Agent.SimpleLogger.start_link(capture_arguments) end
      )
    end
    {:ok, sup_pid}
  end
end
