defmodule Client.CLI do

  def main(args \\ []) do
    {opts, args, invalid} = OptionParser.parse(args, strict: [
      port: :integer,
      #name: :string
    ])
    if opts == [] or (args != [] && invalid != []) do
      IO.puts "usage: p2p_chat --port <port>"
    else
      Client.start_link(opts[:port])
      main_cli()
    end
  end

  def main_cli do
    case gets("=> ") do
      "register" -> register()
      "find" -> find_peer()
      _ -> IO.puts("register or find")
     end
  end

  def register do
    sesstoken = gets("(sesstoken)> ")
    passwd = gets_passwd("(password)> ") |> Client.Crypto.hash()
    GenServer.call(:client, {:register, sesstoken, passwd}) |> IO.inspect()
    main_cli()
  end

  def find_peer do
    name = gets("(my_name)> ")
    sesstoken = gets("(sesstoken)> ")
    passwd = gets_passwd("(password)> ") |> Client.Crypto.hash()
    loading_pid = spawn(fn -> loading_rotate() end)
    peer = GenServer.call(:client, {:find, name, sesstoken, passwd}, :infinity)
    send(loading_pid, :stop)
    GenServer.call(:client, :key, :infinity)
    GenServer.cast(:client, :recv)
    chat(name, peer.name)
  end

  def chat(my_name, peer_name) do
    prompt = "(#{my_name} -> #{peer_name})> "
    text = gets(prompt)
    if String.length(text) > 0 do
      GenServer.call(:client, {:chat, text}) #|> IO.inspect()
    end
    chat(my_name, peer_name)
  end

  defp loading_rotate do
    IO.write(IO.ANSI.clear_line() <> IO.ANSI.cursor_left() <> "|")
    :timer.sleep(100)
    IO.write(IO.ANSI.clear_line() <> IO.ANSI.cursor_left() <> "/")
    :timer.sleep(100)
    IO.write(IO.ANSI.clear_line() <> IO.ANSI.cursor_left() <> "-")
    :timer.sleep(100)
    IO.write(IO.ANSI.clear_line() <> IO.ANSI.cursor_left() <> "\\")
    :timer.sleep(100)
    receive do
      :stop -> IO.write(IO.ANSI.clear_line() <> "\r" <>
      IO.ANSI.light_blue() <> "CHAT START" <> "\n" <> IO.ANSI.reset())
    after
      0 -> loading_rotate()
    end
  end

  defp gets(prompt), do: IO.gets(prompt) |> String.trim()

  def gets_passwd(prompt) do
    pid = spawn(fn -> clear_input(prompt) end)
    value = IO.gets("")
    send(pid, :stop)
    value
  end

  def clear_input(prompt) do
    IO.write(IO.ANSI.clear_line() <> "\r" <> prompt)
    :timer.sleep(10)
    receive do
      :stop -> IO.write("\r")
    after
      0 -> clear_input(prompt)
    end
  end

end
