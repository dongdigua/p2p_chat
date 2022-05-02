defmodule Client do
  #@serverip {124, 233, 181, 208}
  @serverip {127, 0, 0, 1}
  @serverpt 1234

  def connect(port), do: connect("yee", port)
  def connect(username, clientport) do
    {:ok, socket} = :gen_udp.open(clientport, [:binary, active: false])
    :gen_udp.send(socket, @serverip, @serverpt, "from #{username}")
    spawn(fn ->
      find_peer(socket)
      |> then(fn x -> IO.inspect("found peer: " <> inspect(x) <> " from #{clientport}"); x end)
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
    [_, i1, i2, i3, i4, p] = Regex.run(~r/(\d+).(\d+).(\d+).(\d+):(\d+)/, data)
    {{String.to_integer(i1), String.to_integer(i2), String.to_integer(i3), String.to_integer(i4)},
    String.to_integer(p)}
  end

  def connect_peer({ip, port}, socket) do
    spawn(fn -> :gen_udp.recv(socket, 0) |> IO.inspect() end)
    :gen_udp.send(socket, ip, port, "say hi, to #{port}")
  end
end
