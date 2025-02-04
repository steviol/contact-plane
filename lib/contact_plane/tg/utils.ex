defmodule ContactPlane.Tg.Utils do
  @moduledoc """
  utils for using tg api
  """

  require Logger

  alias ContactPlane.Tg
  alias ContactPlane.Utils

  def db_insert([h | t], vk_message_id) do
    db_insert(h, vk_message_id)
    db_insert(t, vk_message_id)
  end

  def db_insert(%{"message_id" => tg_message_id}, vk_message_id) do
    ContactPlane.Repo.insert!(%ContactPlane.Message{
      vk_message_id: vk_message_id,
      tg_message_id: tg_message_id
    })
  end

  def db_insert([], _), do: nil

  def send_message(data, type, vk_message_id) do
    res =
      case type do
        :text -> Tg.invoke("sendMessage", data)
        :single -> Tg.post("sendPhoto", data)
        :multiple -> Tg.post("sendMediaGroup", data)
      end

    case res do
      {:ok, %{"ok" => true, "result" => result}} ->
        Logger.info("Successfully redirected message from vk: #{Utils.inspect(result)}")
        db_insert(result, vk_message_id)

      {:error, _err} ->
        Logger.emergency("Cant redirect message to tg")
    end
  end
end
