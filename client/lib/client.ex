defmodule Client do
  defmodule Peer do
    defstruct [:name, :addr, :port, :pub_key]
  end
  @moduledoc """
  handles client-server IO
  """
  @serveraddr {127, 0, 0, 1}
  @serverpt 1234
  @key_integer <<3>>   #should be a valid key_integer
  use GenServer
  alias Client.Conn
  defstruct [:socket, :name, :priv_key, peer: nil]

  def start_link(port) do
    {:ok, socket} = :gen_udp.open(port, [:binary, active: false])
    GenServer.start_link(Client, %Client{socket: socket}, name: :client)
  end

  def init(%Client{} = client), do: {:ok, client}

  def handle_call({:register, sesstoken, passwd}, _from, client) do
    :ok = :gen_udp.send(client.socket, @serveraddr, @serverpt, Client.Reg.register(sesstoken, passwd))
    {:reply, :gen_udp.recv(client.socket, 0), client}
  end

  def handle_call({:find, name, sesstoken, passwd}, _from, client) do
    :ok = :gen_udp.send(client.socket, @serveraddr, @serverpt, Conn.find_peer(name, sesstoken, passwd))
    case :gen_udp.recv(client.socket, 0) |> Conn.parse_peer() do
      {:ok, peer} ->
        {:reply, peer, %{client | name: name, peer: peer}}
      {:error, reason} ->
        {:reply, reason, client}
    end
  end

  def handle_call(:key, _from, client) do
    {pub, priv} = Client.Crypto.generate_key(@key_integer)
    :ok = :gen_udp.send(client.socket, client.peer.addr, client.peer.port, hd(tl(pub)))
    {:ok, {_addr, _port, peer_pub}} = :gen_udp.recv(client.socket, 0)
    full_peer_pub = [@key_integer, peer_pub]
    {:reply, full_peer_pub,
      %{client | priv_key: priv, peer: %{client.peer | pub_key: full_peer_pub}}
    }
  end

  def handle_call({:chat, text}, _from, client) do
    encrypted = Client.Crypto.encrypt(text, client.peer.pub_key)
    :ok = :gen_udp.send(client.socket, client.peer.addr, client.peer.port, encrypted)
    {:reply, encrypted, client}
  end

  def handle_cast(:recv, client) do
    spawn(fn -> recv_loop(client.socket, client.priv_key) end)
    {:noreply, client}
  end


  defp recv_loop(socket, priv_key) do
    {:ok, {_ip, _port, data}} = :gen_udp.recv(socket, 0)
    decrypted = Client.Crypto.decrypt(data, priv_key)
    IO.puts(Enum.reduce(1..20, "", fn _x, acc -> acc <> IO.ANSI.cursor_left() end)
    <> IO.ANSI.clear_line() <> IO.ANSI.cyan() <> "received: #{inspect(decrypted)}" <> IO.ANSI.reset())
    recv_loop(socket, priv_key)
  end
end
