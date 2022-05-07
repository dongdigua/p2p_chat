defmodule Server.Reg do

  def new do
    :ets.new(:register, [:set, :public, :named_table])
  end

  #return boolean
  def register_session(token, passwd) do
    :ets.insert_new(:register, {token, passwd})
  end

  def session_valid?(token, passwd) do
    :ets.lookup(:register, token) == [{token, passwd}]
  end

end
