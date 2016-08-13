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

  def header([{:ipv4, _, _, _, _, _, _, _, _, _, proto, _, daddr, saddr, _}|rest], acc) do
    header(rest, [{:ipv4, [{:protocol, :pkt.proto(proto)},
                    {:source_address, :inet_parse.ntoa(saddr)},
                    {:destination_address, :inet_parse.ntoa(daddr)}]}|acc])
  end

  def header([{:tcp, dport, sport, ackno, seqno,
            win, cwr, ece, urg, ack, psh,
            rst, syn, fin, _, _, _, _, _}|rest], acc) do
    flags = Enum.filter([{:cwr, cwr}, {:ece, ece}, {:urg, urg}, {:ack, ack},
                   {:psh, psh}, {:rst, rst}, {:syn, syn}, {:fin, fin}],
                   fn({_,v}) -> v == 1 end)
      |> Keyword.keys
    header(rest, [{:tcp, [{:source_port, sport}, {:destination_port, dport},
                    {:flags, flags}, {:seq, seqno}, {:ack, ackno}, {:win, win}]}|acc])
  end

  def header([{:udp, sport, dport, ulen, _}|rest], acc) do
    header(rest, [{:udp, [{:source_port, sport}, {:destination_port, dport},
                    {:ulen, ulen}]}|acc])
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
