defmodule Client do
  defmodule Peer do
    defstruct [:name, :addr, :port]
  end
  @moduledoc """
  handles client-server IO
  """
  @serveraddr {127, 0, 0, 1}
  @serverpt 1234
  use GenServer
  alias Client.Conn
  defstruct [:socket, peer: nil]

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
        {:reply, peer, %{client | peer: peer}}
      {:error, reason} ->
        {:reply, reason, client}
    end
  end

  def handle_call({:chat, text}, _from, client) do
    :ok = :gen_udp.send(client.socket, client.peer.addr, client.peer.port, text)    #TODO: exchange public keys
    {:reply, :ok, client}
  end

  def handle_cast(:recv, client) do
    spawn(fn -> recv_loop(client.socket) end)
    {:noreply, client}
  end


  defp recv_loop(socket) do
    :gen_udp.recv(socket, 0) |> IO.inspect()
    recv_loop(socket)
  end
end
