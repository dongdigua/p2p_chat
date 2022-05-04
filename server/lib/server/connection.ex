defmodule Server.Conn do

  def table_new do
    :ets.new(:connection, [:set, :protected, :named_table])
  end

  #save the peer connection
  #if nether peer exists nor session registered, return nil
  #then the caller function will tell the client
  defp add_peer({{ip, port}, {name, sesstoken, passwd}}) do
    if Server.Reg.session_valid?(sesstoken, passwd) do
      :ets.insert_new(:connection, {sesstoken, {ip, port, name}})
    else
      nil
    end
  end

  @doc """
  find the corresponding peer with the same session_name
  if found, spawn(send peer data to each)
  (user_data is needed to send to each)
  and delete the previous saved data
  if not found, do find_peer
  """
  def find_peer(socket, {{ip, port}, {name, sesstoken, _passwd}} = user_data) do
    peer_found = :ets.lookup(:connection, sesstoken)
    if peer_found == [] do
      add_peer(user_data)
    else
      spawn(fn -> send_to_each(socket, {peer_found |> hd() |> elem(1), {ip, port, name}}) end)
      :ets.delete(:connection, sesstoken)
    end
  end

  def send_to_each(socket, {{ip0, port0, name0}, {ip1, port1, name1}}) do
    msg0 = "PEER#{name1}:#{format_ip(ip1)}:port1"
    msg1 = "PEER#{name0}:#{format_ip(ip0)}:port0"
    :gen_udp.send(socket, ip0, port0, msg0)
    :gen_udp.send(socket, ip1, port1, msg1)
  end

  def require_registion(socket, {{ip, port}, {_name, sesstoken, _passwd}}) do
    :gen_udp.send(socket, ip, port, "ERROR:#{sesstoken} is not registered")
  end

  defp format_ip({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end
end
