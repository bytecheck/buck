defmodule Buck.ConnectionManager do
  @moduledoc false

  use Rabbit.Connection

  require Logger

  # @connection_timeout 60_000

  def start_link(opts \\ []) do
    Rabbit.Connection.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Rabbit.Connection
  def init(:connection_pool, opts) do
    # Perform runtime pool config
    {:ok, opts}
  end

  def init(:connection, _opts) do
    {:ok, Application.fetch_env!(:buck, :connection)}
  end
end
