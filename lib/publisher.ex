defmodule Buck.Publisher do
  @moduledoc """
  Base publisher
  """

  @callback publish(payload :: map() | list()) :: :ok | none

  @callback publish(
              payload :: map() | list(),
              options :: Keyword.t()
            ) :: :ok | none

  @optional_callbacks publish: 2

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      use Rabbit.Producer

      @otp_app Keyword.fetch!(opts, :otp_app)
      @exchange opts[:exchange] || raise(":exchange is required option")

      @behaviour Buck.Publisher

      def start_link(opts \\ []) do
        Rabbit.Producer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      # Callbacks

      @impl Rabbit.Producer
      def init(:producer_pool, opts) do
        # Perform any runtime configuration for the pool
        {:ok, opts}
      end

      def init(:producer, _opts) do
        # Perform any runtime configuration per producer
        config = Application.fetch_env!(@otp_app, __MODULE__) |> Keyword.drop([:custom_meta])

        {:ok, config}
      end

      def publish(payload, options \\ [])

      def publish(payload, options) when is_list(payload) do
        Enum.each(payload, &publish(&1, options))
      end

      def publish(%{event_type: event_type} = payload, options) do
        default_options = [
          content_type: "application/json",
          message_id: UUID.uuid4(),
          timestamp: :os.system_time(),
          app_id: "#{__MODULE__}",
          correlation_id: UUID.uuid4()
        ]

        merged_options = Keyword.merge(default_options, options)

        Rabbit.Producer.publish(__MODULE__, _exchange(), event_type, payload, merged_options)
      end

      def publish(_payload, _options),
        do: raise("Message must contain event_type")

      ## Server Callbacks

      defp _env_postfix do
        Application.get_env(@otp_app, __MODULE__)[:custom_meta][:env_postfix] ||
          raise(":env_postfix is required option")
      end

      defp _exchange do
        @exchange <> _env_postfix()
      end
    end
  end
end
