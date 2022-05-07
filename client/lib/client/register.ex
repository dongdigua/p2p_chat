defmodule Client.Reg do

  def register(token, passwd) do
    "REGISTER:#{token}:#{passwd}"
  end

end
