# Nibbler

## Using Consul

Nibbler uses Consul for auto-discovery of agents. In order for agents to register their availability with Consul you need to configure a default TTL. For example:

```
curl localhost:8500/v1/agent/check/register -X PUT -d '
{
  "name": "service:nibbler_agent",
  "ttl": "15s"
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

