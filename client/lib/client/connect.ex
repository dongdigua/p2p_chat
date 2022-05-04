defmodule Client.Conn do
  defstruct [:name, :port, :sesstoken, :passwd]

  defmodule Peer do
    defstruct [:ip, :port, :name]
  end

  alias Client.Conn
  alias Client.Conn.Peer

  # @serverip {124, 233, 181, 208}
  @serverip {127, 0, 0, 1}
  @serverpt 1234

  def new(name, port, sesstoken, passwd) do
    %Conn{
      name: name,
      port: port,
      sesstoken: sesstoken,
      passwd: passwd
    }
  end

  @doc """
  send data to server
  FROM:foo;SESSTOKEN:test;PASSWD:hash
  """
  def connect(client = %Conn{}) do
    {:ok, socket} = :gen_udp.open(client.port, [:binary, active: false])

    :gen_udp.send(
      socket,
      @serverip,
      @serverpt,
      "FROM:#{client.name};SESSTOKEN:#{client.sesstoken};PASSWD:#{client.passwd}"
    )

    spawn(fn ->
      find_peer(socket)
      |> then(fn x ->
        IO.inspect("found peer: " <> inspect(x) <> " from #{client.port}")
        x
      end)
      |> test_peer()
    end)
  end

  def find_peer(socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, {_, _, data}} ->
        {parse_peer(data), socket}

      {:error, error} ->
        error
    end
  end

  @doc """
  parse data from server
  PEER:foo:192.168.1.20:2333
  or
  ERROR:reason
  """
  defp parse_peer(data) do
    case data do
      <<?P, _::binary>> ->
        [_, name, i1, i2, i3, i4, p] =
          Regex.run(~r/PEER:(\w+):(\d+).(\d+).(\d+).(\d+):(\d+)/, data)
        %Peer{
          ip:
            {String.to_integer(i1), String.to_integer(i2), String.to_integer(i3),
             String.to_integer(i4)},
          port: String.to_integer(p),
          name: name
        }

      <<?E, _::binary>> ->
        IO.inspect(data)
    end
  end

  defp test_peer({peer = %Peer{}, socket}) do
    spawn(fn -> :gen_udp.recv(socket, 0) |> IO.inspect() end)
    :gen_udp.send(socket, peer.ip, peer.port, "say hi, to #{peer.name}")
  end

  defp test_peer(error) do
    IO.inspect(error)
  end
end
