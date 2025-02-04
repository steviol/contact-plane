defmodule ContactPlane.Vk.Listener do
  @moduledoc false

  use GenServer, restart: :permanent

  require Logger

  alias ContactPlane.Vk
  alias ContactPlane.Utils

  @group_id Application.compile_env(:contact_plane, :vk_group_id)

  def start_link(_) do
    {:ok, _} = GenServer.start_link(__MODULE__, 0, name: VkLongpollData)
  end

  def update_data(pid, data \\ %{}) do
    GenServer.cast(pid, {:update, data})
  end

  def get_data(pid) do
    GenServer.call(pid, :get)
  end

  def get_longpoll_data() do
    Logger.info("Getting VK longpoll data")

    res = Vk.invoke("groups.getLongPollServer", %{group_id: @group_id})

    case res do
      {:ok, %{"response" => data}} ->
        Logger.info("Successfuly got longpoll data")
        data

      {:error, err} ->
        Logger.emergency("Cant get longpoll data from VK: #{Utils.inspect({err})}")
        throw(err)
    end
  end

  defp process_response(%{"updates" => updates, "ts" => ts}) do
    Enum.each(updates, fn update ->
      Logger.info("New event from Vk: #{Utils.inspect(update)}")

      Task.start(fn ->
        Vk.Handlers.handle_event(update)
      end)
    end)

    Vk.Listener.update_data(VkLongpollData, %{"ts" => ts})
  end

  defp process_response(%{"failed" => 1, "ts" => ts}) do
    Vk.Listener.update_data(VkLongpollData, %{"ts" => ts})
  end

  defp process_response(_) do
    Vk.Listener.update_data(VkLongpollData)
  end

  def listen() do
    %{
      "server" => server,
      "key" => key,
      "ts" => ts
    } = Vk.Listener.get_data(VkLongpollData)

    body = [
      act: "a_check",
      wait: 25,
      key: key,
      ts: ts
    ]

    res =
      Tesla.request(
        method: :get,
        url: server,
        query: body,
        headers: [{"Content-Type", "application/x-www-form-urlencoded"}],
        opts: [adapter: [recv_timeout: 30_000]]
      )

    case res do
      {:ok, %{body: body}} ->
        process_response(body |> Jason.decode!())

      {:error, %{reason: :nxdomain}} ->
        Vk.Listener.update_data(VkLongpollData)

      {:error, err} ->
        Logger.error("HTTP error while accessing VK longpoll: #{Utils.inspect(err)}")
        Vk.Listener.update_data(VkLongpollData)
    end

    listen()
  end

  # Callbacks

  @impl true
  def init(_) do
    Logger.info("Initializing VK listener")
    _pid = Task.start_link(fn -> listen() end)
    {:ok, get_longpoll_data()}
  end

  @impl true
  def handle_call(:get, _from, data) do
    {:reply, data, data}
  end

  @impl true
  def handle_cast({:update, data}, _) when data == %{} do
    {:noreply, get_longpoll_data()}
  end

  @impl true
  def handle_cast({:update, data}, state) do
    {:noreply, %{state | "ts" => data["ts"]}}
  end
end
