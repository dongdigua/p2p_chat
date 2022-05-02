defmodule Server do
  @serverpt 1234

  def connect_two_peers do
    {:ok, socket} = :gen_udp.open(@serverpt, [:binary, active: false])
    [:gen_udp.recv(socket, 0), :gen_udp.recv(socket, 0)] |> IO.inspect()
    |> send_to_each(socket)
  end

  def send_to_each([peer0, peer1], socket) do
    {:ok, {ip0, port0, _}} = peer0 |> IO.inspect()
    {:ok, {ip1, port1, _}} = peer1 |> IO.inspect()
    :gen_udp.send(socket, ip0, port0, peer_string(ip1, port1)) |> IO.inspect()
    :gen_udp.send(socket, ip1, port1, peer_string(ip0, port0)) |> IO.inspect()
  end

  defp peer_string({i1, i2, i3, i4}, port) do
    "#{i1}.#{i2}.#{i3}.#{i4}:#{port}"
  end
end
