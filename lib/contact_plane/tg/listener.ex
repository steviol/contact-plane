defmodule ContactPlane.Tg.Listener do
  @moduledoc false

  use GenServer, restart: :permanent

  require Logger

  alias ContactPlane.Tg
  alias ContactPlane.Utils

  def start_link(_) do
    {:ok, _} = GenServer.start_link(__MODULE__, 0, name: TgLongpollOffset)
  end

  def update_offset(pid, new) do
    GenServer.cast(pid, {:update, new})
  end

  def get_offset(pid) do
    GenServer.call(pid, :get)
  end

  defp process_response(%{"ok" => true, "result" => updates}) do
    Logger.info("New events from Tg: #{Utils.inspect(updates)}")

    Task.start(fn ->
      Tg.Handlers.handle(updates)
    end)

    Enum.each(updates, fn update ->
      %{"update_id" => update_id} = update

      if update_id >= Tg.Listener.get_offset(TgLongpollOffset) do
        Tg.Listener.update_offset(TgLongpollOffset, update_id + 1)
      end
    end)
  end

  defp process_response(res), do: Logger.error("Tg api error: #{Utils.inspect(res)}")

  def listen() do
    body =
      %{timeout: 25, offset: Tg.Listener.get_offset(TgLongpollOffset)}
      |> URI.encode_query()

    res =
      Tg.request(
        method: :post,
        url: "getUpdates",
        body: body,
        headers: [{"Content-Type", "application/x-www-form-urlencoded"}],
        opts: [adapter: [recv_timeout: 30_000]]
      )

    case res do
      {:ok, %{body: body}} ->
        process_response(body)

      {:error, err} ->
        Logger.error("Http error while requesting getUpdates: #{Utils.inspect(err)}")
        throw(err)
    end

    listen()
  end

  # Callbacks

  @impl true
  def init(offset \\ 0) do
    Logger.info("Initializing Tg listener")
    _pid = Task.start_link(fn -> listen() end)
    {:ok, offset}
  end

  @impl true
  def handle_call(:get, _from, offset) do
    {:reply, offset, offset}
  end

  @impl true
  def handle_cast({:update, new}, _old) do
    {:noreply, new}
  end
end
