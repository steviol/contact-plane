defmodule ContactPlane.Vk.Handlers do
  @moduledoc """
  Хендлеры для ивентов вк
  """

  require Logger
  require Ecto.Query

  alias ContactPlane.Tg
  alias ContactPlane.Vk
  alias ContactPlane.Utils
  alias Tesla.Multipart

  @vk_chat Application.compile_env(:contact_plane, :vk_chat)
  @tg_chat Application.compile_env(:contact_plane, :tg_chat)
  @vk_muted_ids Application.compile_env(:contact_plane, :vk_muted_ids)

  defp get_highest_quality([h | t]), do: get_highest_quality(t, h)

  defp get_highest_quality([h | t], acc) do
    case h["height"] > acc["height"] do
      true -> get_highest_quality(t, h)
      false -> get_highest_quality(t, acc)
    end
  end

  defp get_highest_quality([], result), do: result

  defp get_name(from_id) do
    res =
      Vk.invoke("users.get", %{
        user_ids: from_id
      })

    case res do
      {:ok,
       %{
         "response" => [
           %{
             "first_name" => first_name,
             "last_name" => last_name
           }
         ]
       }} ->
        "#{first_name} #{last_name}"

      _ ->
        "<unknown>"
    end
  end

  defp get_message_text(name, text) do
    "<b>#{HtmlEntities.encode(name)}:</b> #{HtmlEntities.encode(text)}"
  end

  defp get_tg_relative_message(vk_message_id) do
    res =
      ContactPlane.Message
      |> Ecto.Query.where(vk_message_id: ^vk_message_id)
      |> ContactPlane.Repo.all()
      |> List.first

    case res do
      %ContactPlane.Message{
        vk_message_id: _,
        tg_message_id: reply_id
      } ->
        reply_id

      _ ->
        nil
    end
  end

  defp merge_if_reply(params, %{"conversation_message_id" => vk_reply_id}) do
    reply_id = get_tg_relative_message(vk_reply_id)

    case reply_id do
      nil -> params
      _ -> params |> Map.merge(%{reply_to_message_id: reply_id})
    end
  end

  defp merge_if_reply(params, _), do: params

  defp merge_multipart_if_reply(params, %{"conversation_message_id" => vk_reply_id}) do
    params
    |> Multipart.add_field("reply_to_message_id", "#{get_tg_relative_message(vk_reply_id)}")
  end

  defp merge_multipart_if_reply(params, _), do: params

  defp merge_multipart_files(mp, [h | t], acc) do
    %{"photo" => %{"sizes" => sizes}} = h
    %{"url" => url} = get_highest_quality(sizes)
    res = Tesla.get(url)

    case res do
      {:ok, %{body: body}} ->
        mp
        |> Multipart.add_file_content(body, "file_#{acc}", name: "file_#{acc}")
        |> merge_multipart_files(t, acc + 1)

      _ ->
        Logger.error("")
    end
  end

  defp merge_multipart_files(mp, [], _), do: mp

  defp handle_message(:text, %{
         "conversation_message_id" => vk_message_id,
         "from_id" => from_id,
         "reply_message" => reply_message,
         "peer_id" => @vk_chat,
         "text" => text
       })
       when from_id not in @vk_muted_ids do
    %{
      chat_id: @tg_chat,
      parse_mode: "HTML",
      text: get_message_text(get_name(from_id), text)
    }
    |> merge_if_reply(reply_message)
    |> Tg.Utils.send_message(:text, vk_message_id)
  end

  defp handle_message(:single, %{
         "conversation_message_id" => vk_message_id,
         "attachments" => [attachment],
         "from_id" => from_id,
         "reply_message" => reply_message,
         "peer_id" => @vk_chat,
         "text" => text
       })
       when from_id not in @vk_muted_ids do
    %{"photo" => %{"sizes" => sizes}} = attachment
    %{"url" => url} = get_highest_quality(sizes)
    res = Tesla.get(url)

    case res do
      {:ok, %{body: body}} ->
        Multipart.new()
        |> Multipart.add_file_content(body, "", name: "photo")
        |> Multipart.add_field("chat_id", "#{@tg_chat}")
        |> Multipart.add_field("caption", get_message_text(get_name(from_id), text))
        |> Multipart.add_field("parse_mode", "HTML")
        |> merge_multipart_if_reply(reply_message)
        |> Tg.Utils.send_message(:single, vk_message_id)
    end
  end

  defp handle_message(:multiple, %{
         "conversation_message_id" => vk_message_id,
         "from_id" => from_id,
         "attachments" => attachments,
         "reply_message" => reply_message,
         "peer_id" => @vk_chat,
         "text" => text
       })
       when from_id not in @vk_muted_ids do
    [media_h | media_t] =
      for(
        n <- 1..(attachments |> length),
        do: %{type: "photo", media: "attach://file_#{n}"}
      )

    media_h =
      media_h
      |> Map.merge(%{
        caption: get_message_text(get_name(from_id), text),
        parse_mode: "HTML"
      })

    media = [media_h | media_t] |> Jason.encode!()

    Multipart.new()
    |> Multipart.add_field("media", media)
    |> Multipart.add_field("chat_id", "#{@tg_chat}")
    |> Multipart.add_field("parse_mode", "HTML")
    |> merge_multipart_if_reply(reply_message)
    |> merge_multipart_files(attachments, 1)
    |> Tg.Utils.send_message(:multiple, vk_message_id)
  end

  def handle_event(%{
        "event_id" => _event_id,
        "object" => %{
          "message" => message
        },
        "type" => "message_new"
      }) do
    message
    |> Map.put_new("reply_message", nil)
    |> then(fn msg ->
      case msg |> Map.get("attachments", []) |> length() do
        0 -> handle_message(:text, msg)
        1 -> handle_message(:single, msg)
        _ -> handle_message(:multiple, msg)
      end
    end)
  end

  def handle_event(event),
    do: Logger.warning("Unhandled vk event: #{Utils.inspect(event)}")
end
