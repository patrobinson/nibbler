defmodule Nibbler.Agent.PcapDumper do
  # See https://wiki.wireshark.org/Development/LibpcapFileFormat for explination of the format

  @magic_number 0xa1b2c3d4
  @version_major 2
  @version_minor 4

  def with_stream(stream) do
    file_name = Application.get_env(:nibbler, :pcap_file)
    {:ok, pcap_file} = File.open file_name, [:write]
    packet = {:packet, dlt, _, _, _} = Stream.take(stream, 1) |> Enum.to_list |> List.first
    write_header(pcap_file, 65535, dlt)
    write_packet(pcap_file, packet)
    for event <- stream do
      write_packet(pcap_file, event)
    end
    File.close pcap_file
  end

  defp write_header(file, len, dlt) do
    header = <<@magic_number :: size(32),
      @version_major :: size(16),
      @version_minor :: size(16),
      0 :: size(32), # Assume all timestamps are in GMT
      0 :: size(32), # Timestamps are 100% accurate
      len :: size(32),
      dlt :: size(32)
      >>
    IO.binwrite(file, header)
  end

  defp write_packet(file, {:packet, dlt, time, len, data}) do
    {mega_sec, sec, micro_sec} = time
    seconds = mega_sec * 1000000 + sec
    caplen = byte_size(data)
    IO.binwrite(
      file,
      [
        <<seconds :: size(32),
        micro_sec :: size(32),
        caplen :: size(32),
        len :: size(32),
        >>,
        data
      ]
    )
  end
end
