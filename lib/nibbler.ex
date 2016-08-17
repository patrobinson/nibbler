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
    agent_command = Application.get_env(:nibbler, :agent_command)
    children = [
      worker(Discovery.Poller, [node_pattern, Discovery.Handler.NodeConnect], id: Nibbler.Master.MyPoller),
    ]
    opts = [strategy: :one_for_one, name: Nibbler.Master.Supervisor]
    {:ok, sup_pid} = Supervisor.start_link(children, opts)
    Process.sleep(5000)
    capture_arguments = Application.get_env(:nibbler, :capture_arguments)
    for node <- Discovery.nodes(node_pattern) do
      Task.Supervisor.async(
        {Nibbler.Agent.TaskSupervisor, node},
        Nibbler,
        :callback_with_stream,
        [agent_command, capture_arguments]
      )
    end
    {:ok, sup_pid}
  end

  def callback_with_stream(callback, capture_arguments) do
    {:ok, pid} = GenEvent.start_link([])
    GenEvent.add_handler(pid, Nibbler.Agent.PacketHandler, capture_arguments)
    stream_callback = quote do
      unquote(pid) |> GenEvent.stream |> unquote(callback).with_stream
    end
    Code.eval_quoted stream_callback
  end
end
