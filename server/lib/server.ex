defmodule Server do
  defmodule UserData do
    defstruct [:addr, :port, :name, :sesstoken, :passwd]
  end
  import Server.Conn
  @serverpt 1234

  def start do
    Server.Reg.new()
    Server.Conn.table_new()
    {:ok, socket} = :gen_udp.open(@serverpt, [:binary, active: false])
    serve(socket)
  end

  def serve(socket) do
    case :gen_udp.recv(socket, 0) |> IO.inspect() do
      {:ok, {_ip, _port, <<?F, _rest::binary>>} = data} ->
        #FROM:foo;SESSTOKEN:test;PASSWD:hash
        spawn(fn -> handle_connection(socket, data) end)
      {:ok, {_ip, _port, <<?R, _rest::binary>>} = data} ->
        #REGISTER:token:passwd
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
    user_data = %UserData{
      addr: ip,
      port: port,
      name: name,
      sesstoken: sesstoken,
      passwd: passwd
    }

  end

  def handle_register(socket, {ip, port, bin}) do
    [_, token, passwd] = Regex.run(~r/REGISTER:(\w+):(\w+)/, bin)
    if Server.Reg.register_session(token, passwd) do
      :gen_udp.send(socket, ip, port, "successful!")
    else
      :gen_udp.send(socket, ip, port, "exists")
    end
  end

end
