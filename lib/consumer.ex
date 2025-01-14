# credo:disable-for-this-file Credo.Check.Warning.ApplicationConfigInModuleAttribute
defmodule Buck.Consumer do
  @moduledoc """
  Base consumer
  """

  @callback consume(payload :: any()) ::
              :ok | none()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      use Rabbit.Consumer

      require Logger

      @otp_app Keyword.fetch!(opts, :otp_app)
      @bind Keyword.fetch!(opts, :bind)

      @behaviour Buck.Consumer

      def start_link(opts \\ []) do
        Rabbit.Consumer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl Rabbit.Consumer
      def init(:consumer, opts) do
        # Perform runtime config
        config = Application.fetch_env!(@otp_app, __MODULE__)
        auto_sub? = config[:custom_meta][:auto_subscribed?] || :not_set

        if config[:custom_meta][:auto_subscribed?] == true do
          custom_meta = (config[:custom_meta] || []) |> Enum.into(%{})

          config =
            config
            |> Keyword.put(:custom_meta, custom_meta)
            |> Keyword.put(:queue, _queue())

          {:ok, config}
        else
          Logger.info("""
          #{__MODULE__} did not subscribe, because auto_subscribed? is #{inspect(auto_sub?)}
          """)
          :ignore
        end
      end

      @impl Rabbit.Consumer
      def handle_setup(state) do
        # Optional callback to perform exchange or queue setup
        :ok =
          AMQP.Exchange.declare(
            state.channel,
            _exchange(),
            _exchange_only()[:type],
            _exchange_only()[:options]
          )

        {:ok, _} = AMQP.Queue.declare(state.channel, _error_queue(), durable: true)

        {:ok, _} =
          AMQP.Queue.declare(state.channel, _queue(),
            durable: true,
            arguments: [
              {"x-dead-letter-exchange", :longstr, ""},
              {"x-dead-letter-routing-key", :longstr, _error_queue()}
            ]
          )

        Enum.each(@bind, fn b ->
          b = Enum.into(b, [])

          :ok =
            AMQP.Queue.bind(state.channel, _queue(), _exchange(), b)
        end)

        :ok
      end

      @impl Rabbit.Consumer
      def handle_message(%{decoded_payload: decoded_payload} = message) do
        # Handle consumed messages

        payload = if Map.get(message, :decoded_payload) == nil do
          inspect(message.payload)
        else
          inspect(message.decoded_payload)
        end

        Logger.info("""
        [#{__MODULE__}] processing incoming message
        Event type: #{decoded_payload["event_type"]}
        Message id: #{message.meta.message_id}
        Event data: #{payload}
        Meta #{inspect(message.meta)}
        """)

        :ok = consume(message.decoded_payload)

        Logger.info("""
        [#{__MODULE__}] message processed.
        Message id: #{message.meta.message_id}
        """)

        {:ack, message}
      end

      @impl Rabbit.Consumer
      def handle_error(message) do
          reject_count = _get_count(message.meta.headers)
          payload = if message.decoded_payload do
            inspect(message.decoded_payload)
          else
            inspect(message.payload)
          end

          Logger.error("""
            #{__MODULE__} failed to process message
            Retry count: #{reject_count}
            Message id: #{message.meta.message_id}
            Error: #{inspect(message.error_reason)}
            Stacktrace: #{inspect(message.error_stack)}
            Channel: #{inspect(message.channel)}
            Meta: #{inspect(message.meta)}
            Redilevered?: #{message.meta.redelivered}
            Payload: #{payload}
          """)

        {:reject, message, requeue: not message.meta.redelivered}
      end

      defp _get_count(:undefined), do: 0

      defp _get_count(headers) do
        case Enum.find(headers, fn {k, _type, _value} -> k == "x-death" end) do
          {"x-death", _, [table: table]} -> Enum.find(table, fn {k, _, _} -> k == "count" end) |> elem(2)
          _ -> nil
        end
      end

      defp _count_or_default(not_count), do: not_count

      defp _env_postfix do
        Application.get_env(@otp_app, __MODULE__)[:custom_meta][:env_postfix] ||
          raise(":env_postfix is required option")
      end

      defp _queue do
        _queue_only() <> _env_postfix()
      end

      defp _error_queue do
        "#{_queue_only()}#{_env_postfix()}_error"
      end

      defp _exchange do
        _exchange_only()[:name] <> _env_postfix()
      end

      defp _exchange_only do
        Application.get_env(@otp_app, __MODULE__)[:custom_meta][:exchange] ||
          raise(":exchange is required option")
      end

      defp _queue_only do
        Application.get_env(@otp_app, __MODULE__)[:queue] ||
          raise(":queue is required option")
      end
    end
  end
end
