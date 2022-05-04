defmodule Server do
  import Server.Conn
  @serverpt 1234

  def start do
    {:ok, socket} = :gen_udp.open(@serverpt, [:binary, active: false])
    serve(socket)
  end

  def serve(socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, {_ip, _port, <<?F, _rest::binary>>} = data} ->
        #FROM:foo;SESSTOKEN:test;PASSWD:hash
        spawn(fn -> handle_connection(socket, data) end)
      {:ok, {_ip, _port, <<?R, _rest::binary>>} = data} ->
        #TODO
        spawn(fn -> handle_register(socket, data) end)
      {:error, error} ->
        IO.inspect(error)
      _ ->
        nil
    end
    serve(socket)
  end

  def handle_connection(socket, {ip, port, bin}) do
    [_, name, sesstoken, passwd] = Regex.run(~r/FROM:(\w+);SESSTOKEN:(\w+);PASSWD:(\w+)/, bin)
    userdata = {{ip, port}, {name, sesstoken, passwd}}
    #ALL user_data should in this pattern
    if !find_peer(socket, userdata) do
      require_registion(socket, userdata)
    end
  end

  def handle_register(socket, data) do
    "TODO"
  end

end
