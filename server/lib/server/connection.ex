defmodule Server.Conn do

  def table_new do
    :ets.new(:connection, [:set, :public, :named_table])
  end

  @doc """
  save the peer connection
  if nether peer exists nor session registered, return nil
  then the caller function will tell the client
  """
  def add_peer(user_data) do
    if Server.Reg.session_valid?(sesstoken, passwd) do
      :ets.insert_new(:connection, {user_data.sesstoken, {user_data.addr, user_data.port, user_data.name}})
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
  def find_peer(user_data) do
    peer_found = :ets.lookup(:connection, user_data.sesstoken)
    peer_found != []
  end

  def send_to_each({{ip0, port0, name0}, {ip1, port1, name1}}) do
    msg0 = "PEER:#{name1}:#{format_ip(ip1)}:port1"
    msg1 = "PEER:#{name0}:#{format_ip(ip0)}:port0"
  end

  def require_registion() do
  end

  defp format_ip({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end
end
