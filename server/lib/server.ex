defmodule Server do
  @serverpt 1234

  def connect_two_peers do
    {:ok, socket} = :gen_udp.open(@serverpt, [:binary, active: false])
    serve(socket)
  end

  def serve(socket) do
    [:gen_udp.recv(socket, 0), :gen_udp.recv(socket, 0)]
    |> send_to_each(socket)
    serve(socket)
  end
  def send_to_each([peer, peer], socket) do
    {:ok, {ip, port, _name}} = peer
    :gen_udp.send(socket, ip, port, "error")
  end
  def send_to_each([peer0, peer1], socket) do
    {:ok, {ip0, port0, name0}} = peer0 |> IO.inspect()
    {:ok, {ip1, port1, name1}} = peer1 |> IO.inspect()
    :gen_udp.send(socket, ip0, port0, peer_string(ip1, port1, name1)) |> IO.inspect()
    :gen_udp.send(socket, ip1, port1, peer_string(ip0, port0, name0)) |> IO.inspect()
  end

  defp peer_string({i1, i2, i3, i4}, port, name) do
    [_, name_parsed] = Regex.run(~r/FROM:(\w+)/, name)
    "PEER:#{name_parsed}:#{i1}.#{i2}.#{i3}.#{i4}:#{port}"
  end
end
