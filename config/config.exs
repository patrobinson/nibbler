# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :nibbler, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:nibbler, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#
config :nibbler, mode: :master
config :nibbler, agent_command: Nibbler.Agent.PcapDumper
config :nibbler, heartbeat_check: "service:nibbler_agent"
config :nibbler, heartbeat_ttl: 10000
config :nibbler, pcap_file: "./output.pcap"
config :nibbler, capture_arguments: [{"interface", ["en0"]}, {"timeout", 10000}] # Example

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#

import_config "#{Mix.env}.exs"
