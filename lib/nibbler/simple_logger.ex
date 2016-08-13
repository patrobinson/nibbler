defmodule Nibbler.SimpleLogger do
  use GenServer
  require Logger

  def start_link(opts \\ []),
  do: GenServer.start_link(__MODULE__, opts)

  def init(opts),
  do: :epcap.start_link(opts)

  def handle_info({packet, dlt, _time, _len, data}, _) do
    headers = decode(dlt, data) |> header
  end

  # Internal functions

  def decode(dlt, data),
  do: :pkt.decapsulate({:pkt.dlt(dlt), data})

  def header(payload),
  do: header(payload, [])

  def header([], acc),
  do: Enum.reverse(acc)

  def header([{:ether, shost, dhost, _, _}|rest], acc) do
    rest
    |> header(
      [
        {:ether,
          [
            {:source_macaddr, ether_addr(shost)},
            {:destination_macaddr, ether_addr(dhost)}
          ]
        }|acc
      ]
    )
  end

  def ether_addr(mac) do
    hex_list = for <<n <- mac>>, do: Base.encode16(<<n>>)
    hex_list |> Enum.join(":")
  end

end
