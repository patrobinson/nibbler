# Nibbler

Nibbler is designed as a diagnostic tool for distributed systems. It currently supports packet captures, but could be expanded to support many kinds of system analysis.

It has two modes, agent and master. The agent "checks in" to a Consul agent (assumed to be running locally) and listens for connections via Erlang Port Mapper Daemon (epmd). The master finds agents using Consul service discovery, connects to them and triggers a packet capture with the specified "agent command" which is a pre-defined module. The two modules that currently exist are:

Nibbler.Agent.PcapDumper - Dump packet capture to a file
Nibbler.Agent.SimpleLogger - Log serialised packets as info

SimpleLogger has quite a few caveats, the serialised output is difficult to read and it crashes if it inspects a packet type it does not recognise.

## Using Consul

Nibbler uses Consul for auto-discovery of agents. In order for agents to register their availability with Consul you need to configure a service. For example:

```
curl localhost:8500/v1/agent/service/register -X PUT -d '
{
  "name": "nibbler_agent",
  "check": {
    "ttl": "15s"
  },
  "tags": [
    "otp_name:nibbler_agent@laptop"
  ]
}'
```

Where `service:nibbler_agent` is the heartbeat_check variable defined in the config.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `nibbler` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:nibbler, "~> 0.1.0"}]
    end
    ```

  2. Ensure `nibbler` is started before your application:

    ```elixir
    def application do
      [applications: [:nibbler]]
    end
    ```

