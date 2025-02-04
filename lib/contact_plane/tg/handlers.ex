defmodule ContactPlane.Tg.Handlers do
  @moduledoc """
  Хендлеры для ивентов тг
  """

  require Logger

  alias ContactPlane.Utils
  alias ContactPlane.Vk
  alias ContactPlane.Tg
  alias Tesla.Multipart

  @vk_chat Application.compile_env(:contact_plane, :vk_chat)
  @tg_chat Application.compile_env(:contact_plane, :tg_chat)

  def upload_photo(photo_binary, peer_id, name) do
    {:ok, %{"response" => %{"upload_url" => upload_url}}} =
      Vk.invoke("photos.getMessagesUploadServer", %{
        peer_id: peer_id
      })

    mp =
      Multipart.new()
      |> Multipart.add_file_content(photo_binary, "photo", name: "photo")

    Tesla.post(upload_url,mp)
  end

  defp send_message(params, tg_message_id) do
    %{message: message} = params
    message = message |> String.replace(~r"vto\.pe", "[REDACTED]")
    params = params |> Map.replace!(:message, message)
    res = Vk.invoke("messages.send", params)

    case res do
      {:ok, %{"response" => [%{"conversation_message_id" => vk_message_id}]}} ->
        Logger.info("Successfully redirected message from tg")

        ContactPlane.Repo.insert!(%ContactPlane.Message{
          vk_message_id: vk_message_id,
          tg_message_id: tg_message_id
        })

      {:error, err} ->
        Logger.emergency("Cant redirect message to vk: #{Utils.inspect(err)}")
    end
  end

  def handle_message(:text, %{
        "chat" => %{
          "id" => @tg_chat
        },
        "from" => %{
          "first_name" => first_name,
          "last_name" => last_name
        },
        "text" => text,
        "message_id" => tg_message_id
      }) do
    params = %{
      peer_ids: "#{@vk_chat}",
      random_id: 0,
      message: "#{first_name} #{last_name}: #{text}"
    }

    params
    |> send_message(tg_message_id)
  end

  def handle_message(:single, %{
        "chat" => %{
          "id" => @tg_chat
        },
        "from" => %{
          "first_name" => first_name,
          "last_name" => last_name
        },
        "caption" => text,
        "message_id" => tg_message_id,
        "photo" => photo
      }) do
    %{"file_id" => file_id} = photo |> Enum.max_by(& &1["file_size"])

    case Tg.dl(file_id) do
      {:ok, %{body: body}} ->
        Logger.debug(body)

      {:error, err} ->
        Logger.error("#{err}")
    end

    # params = %{
    #   peer_ids: "#{@vk_chat}",
    #   random_id: 0,
    #   message: "#{first_name} #{last_name}: #{text}"
    # }

    # params
    # |> send_message(tg_message_id)
  end

  def handle_message(:multiple, %{
        "chat" => %{
          "id" => @tg_chat
        },
        "from" => %{
          "first_name" => first_name,
          "last_name" => last_name
        },
        "message_id" => tg_message_id,
        "media_group_id" => media_group_id
      }) do
  end

  defp handle_message_group(:single, messages) do
    messages
    |> Enum.each(fn %{"message" => message} ->
      case message do
        %{"photo" => _} ->
          handle_message(:single, message |> Map.put_new("caption", ""))

        _ ->
          handle_message(:text, message)
      end
    end)
  end

  defp handle_message_group(:multiple, messages) do
    :cringe
  end

  def handle(events) do
    event_groups =
      events
      |> Enum.group_by(& &1["media_group_id"])
      |> tap(fn x -> Logger.info("Event groups: #{inspect(x)}") end)
      |> Enum.each(fn x ->
        case x do
          {nil, messages} ->
            handle_message_group(:single, messages)

          {_, messages} ->
            handle_message_group(:multiple, messages)
        end
      end)
  end
end
