defmodule LndClient.Managers.InvoiceEventManager do
  use GenServer

  require Logger

  def start_link(state \\ nil) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def stop(reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(__MODULE__, reason, timeout)
  end

  def init(state) do
    {:ok, state}
  end

  def monitor(pid) do
    GenServer.cast(__MODULE__, {:monitor, %{pid: pid}})
  end

  def handle_cast({:monitor, %{pid: pid}}, state) do
    Logger.info("Will send invoice events to #{inspect(pid)}")

    response =
      Lnrpc.Lightning.Stub.subscribe_invoices(
        state.channel,
        Lnrpc.InvoiceSubscription.new(),
        metadata: %{macaroon: state.macaroon}
      )

    case response do
      {:ok, stream} ->
        stream
        |> decode_stream(pid)

      {:error, %GRPC.RPCError{status: 2}} ->
        Logger.warn("Disconnected from invoice events")

      {:error, error} ->
        Logger.error("Unknown invoice GRPC error")
        IO.inspect(error)
    end

    {:noreply, state}
  end

  defp decode_stream(stream, pid) do
    stream
    |> Enum.each(fn
      {:ok, event} ->
        send(pid, event)

      {:error, _details} ->
        IO.puts("Error while decoding stream")
    end)
  end
end
