defmodule Plug.Session.REDIS do
  import Redbird.Redis
  require IEx

  @moduledoc """
  Stores the session in a redis store.
  """

  @behaviour Plug.Session.Store

  @max_session_time 86_164 * 30

  def init(opts) do
    opts
  end

  def get(_conn, namespaced_key, _opts) do
    case get(namespaced_key) do
      :undefined ->
        {nil, %{}}

      value ->
        if refresh_on_touch(), do: expire(namespaced_key, session_expiration())
        {namespaced_key, value |> :erlang.binary_to_term()}
    end
  end

  def put(conn, nil, data, init_options) do
    put(conn, add_namespace(generate_random_key()), data, init_options)
  end

  def put(_conn, namespaced_key, data, _init_options) do
    set_key_with_retries(
      namespaced_key,
      data,
      session_expiration(),
      1
    )
  end

  defp set_key_with_retries(key, data, expiration_time_seconds, counter) do
    case setex(%{key: key, value: data, seconds: expiration_time_seconds}) do
      :ok ->
        key

      response ->
        if counter > 10 do
          Redbird.RedisError.raise(error: response, key: key)
        else
          set_key_with_retries(key, data, expiration_time_seconds, counter + 1)
        end
    end
  end

  def delete(_conn, redis_key, _init_options) do
    del(redis_key)
    :ok
  end

  defp add_namespace(key) do
    namespace() <> key
  end

  @default_namespace "redbird_session_"
  def namespace do
    Application.get_env(:redbird, :key_namespace, @default_namespace)
  end

  defp generate_random_key do
    :crypto.strong_rand_bytes(96) |> Base.encode64()
  end

  defp session_expiration do
    Application.get_env(:redbird, :expiration_in_seconds, @max_session_time)
  end

  defp refresh_on_touch do
    Application.get_env(:redbird, :refresh_on_touch, false)
  end
end

defmodule Redbird.RedisError do
  defexception [:message]
  @base_message "Redbird was unable to store the session in redis."

  def raise(error: error, key: key) do
    message = "#{@base_message} Redis Error: #{error} key: #{key}"
    raise __MODULE__, message
  end

  def exception(message) do
    %__MODULE__{message: message}
  end
end
