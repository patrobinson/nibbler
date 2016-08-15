# Define an Event Handler for packets
defmodule Nibbler.Agent.PacketHandler do
  use GenEvent

  def handle_event({:packet, x}, packets) do
    {:ok, [x | packets]}
  end

  def handle_info(packet_data, state) when is_tuple(packet_data) do
    GenEvent.notify(self(), packet_data)
    {:ok, state}
  end

  def init(opts) do
    :epcap.start_link(opts)
    {:ok, []}
  end
end
