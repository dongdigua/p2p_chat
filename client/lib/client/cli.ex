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
      #"chat" -> chat()
      _ -> IO.puts("register, find or chat")
     end
  end

  def register do
    sesstoken = gets("(sesstoken)> ")
    passwd = gets("(password)> ") |> Client.Crypto.hash()
    GenServer.call(:client, {:register, sesstoken, passwd}) |> IO.inspect()
    main_cli()
  end

  def find_peer do
    name = gets("(name)> ")
    sesstoken = gets("(sesstoken)> ")
    passwd = gets("(password)> ") |> Client.Crypto.hash()
    peer = GenServer.call(:client, {:find, name, sesstoken, passwd}, :infinity)
    GenServer.cast(:client, :recv)
    chat(name, peer.name)
  end

  def chat(my_name, peer_name) do
    prompt = "(#{my_name} -> #{peer_name})> "
    text = gets(prompt)
    if String.length(text) > 0 do
      GenServer.call(:client, {:chat, text}) |> IO.inspect()
    end
    chat(my_name, peer_name)
  end


  defp gets(prompt), do: IO.gets(prompt) |> String.trim()
end
