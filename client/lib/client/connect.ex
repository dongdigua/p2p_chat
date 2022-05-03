defmodule Client.Conn do
  defmodule Peer do
    defstruct [:ip, :port, :name]
  end
  alias Client.Conn.Peer

  #@serverip {124, 233, 181, 208}
  @serverip {127, 0, 0, 1}
  @serverpt 1234

  def new(name, port, sesstoken, passwd) do
    %Client{
      name: name,
      port: port,
      sesstoken: sesstoken,
      passwd: passwd,
    }
  end

  def connect(client = %Client{}) do
    {:ok, socket} = :gen_udp.open(client.port, [:binary, active: false])
    :gen_udp.send(socket, @serverip, @serverpt, "FROM:#{client.name}")
    spawn(fn ->
      find_peer(socket)
      |> then(fn x -> IO.inspect("found peer: " <> inspect(x) <> " from #{client.port}"); x end)
      |> connect_peer(socket)
    end)
  end

  def find_peer(socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, {_, _, data}} ->
        parse_peer(data)
      {:error, error} ->
        error
    end
  end

  defp parse_peer(data) do
    [_, name, i1, i2, i3, i4, p] = Regex.run(~r/PEER:(\w+):(\d+).(\d+).(\d+).(\d+):(\d+)/, data)
    %Peer{
      ip: {String.to_integer(i1), String.to_integer(i2), String.to_integer(i3), String.to_integer(i4)},
      port: String.to_integer(p),
      name: name
    }
  end

  defp connect_peer(peer = %Peer{}, socket) do
    spawn(fn -> :gen_udp.recv(socket, 0) |> IO.inspect() end)
    :gen_udp.send(socket, peer.ip, peer.port, "say hi, to #{peer.name}")
  end

  defp connect_peer(error, _socket) do
    IO.inspect(error)
  end
end
