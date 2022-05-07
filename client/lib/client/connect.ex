defmodule Client.Conn do

  def find_peer(name, sesstoken, passwd) do
    "FROM:#{name};SESSTOKEN:#{sesstoken};PASSWD:#{passwd}"
  end
  @doc """
  parse data from server
  PEER:foo:192.168.1.20:2333
  or
  ERROR:reason
  """
  def parse_peer({:ok, recv}) do
    recv |> IO.inspect()
    parse_data(elem(recv, 2))
  end

  def parse_peer(error), do: error

  defp parse_data(data) do
    case data do
      <<?P, _::binary>> ->
        [_, name, i1, i2, i3, i4, p] =
          Regex.run(~r/PEER:(\w+):(\d+).(\d+).(\d+).(\d+):(\d+)/, data)
        {:ok, %Client.Peer{
          addr:
            {String.to_integer(i1), String.to_integer(i2), String.to_integer(i3),
             String.to_integer(i4)},
          port: String.to_integer(p),
          name: name
        }}

      <<?E, _::binary>> ->
        {:error, data}
    end
  end

end
