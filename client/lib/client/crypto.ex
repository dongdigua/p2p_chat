defmodule Client.Crypto do
  @key_size 512

  def generate_key(username) do
    {_pub, _priv} = :crypto.generate_key(:rsa, {@key_size, username})
  end

  def encrypt(msg, pubkey) do
    :crypto.public_encrypt(:rsa, msg, pubkey, [])
  end

  def decrypt(msg_encrypted, privkey) do
    :crypto.private_decrypt(:rsa, msg_encrypted, privkey, [])
  end

  def hash(text) do
    :crypto.hash(:sha256, text)
    |> Base.encode16()
  end
end
