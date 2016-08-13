defmodule Nibbler.SimpleLogger do
  use GenServer
  require Logger

  def start_link(opts \\ []),
  do: GenServer.start_link(__MODULE__, opts)

  def init(opts),
  do: :epcap.start_link(opts)

  def handle_info({_packet, dlt, time, len, data}, _) do
    headers = decode(dlt, data) |> header
    Logger.info(inspect [
      {"pcap", [
        {"time", timestamp(time)},
        {"caplen", byte_size(data)},
        {"len", len},
        {"datalink", :pkt.dlt(dlt)}
      ]}
    ] ++ headers)
    {:noreply, "sniffing"}
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

  def header([hdr|rest], acc) when is_tuple(hdr),
  do: header(rest, [{:header, hdr}|acc])

  def header([payload|rest], acc) when is_binary(payload) do
    header(rest, [{:payload, payload},
            {:payload_size, byte_size(payload)}|acc])
  end

  def ether_addr(mac) do
    hex_list = for <<n <- mac>>, do: Base.encode16(<<n>>)
    hex_list |> Enum.join(":")
  end

  def timestamp(now) do
    {{year, month, day}, {hour, minute, second}} = :calendar.now_to_local_time(now)
    {:ok, ntime} = NaiveDateTime.new(year, month, day, hour, minute, second)
    NaiveDateTime.to_iso8601(ntime)
  end
end
