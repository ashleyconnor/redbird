defmodule Redbird.Redis do
  def start_link(name) do
    {:ok, client} = Exredis.start_link()
    true = Process.register(client, name)
    {:ok, client}
  end

  def get(key) do
    Exredis.Api.get(pid(), key)
  end

  def setex(%{key: key, value: value, seconds: seconds}) do
    Exredis.Api.setex(pid(), key, seconds, value)
  end

  def del(key) do
    Exredis.Api.del(pid(), key)
  end

  def keys(pattern) do
    Exredis.Api.keys(pattern)
  end

  def pid do
    :redbird_phoenix_session
  end

  def expire(key, expiration_in_seconds) do
    Exredis.Api.expire(pid(), key, expiration_in_seconds)
  end

  def ttl(key) do
    Exredis.Api.ttl(pid(), key)
  end
end
