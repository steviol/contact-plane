defmodule ContactPlane.Vk.Utils do
  @moduledoc """
  utils for vk api
  """

  require Logger

  alias Tesla.Multipart
  alias ContactPlane.Tg
  alias ContactPlane.Vk
  alias ContactPlane.Utils

  # defp handle_db_response(nil, user_id) do
  #   %{
  #     "response" => [
  #       %{
  #         "first_name" => first_name,
  #         "last_name" => last_name
  #       }
  #     ]
  #   } =
  #     ContactPlane.Vk.invoke(
  #       "users.get",
  #       %{user_ids: user_id}
  #     )

  #   ContactPlane.Repo.insert!(%ContactPlane.Vk.User{
  #     user_id: user_id,
  #     name: "#{first_name} #{last_name}"
  #   })

  #   get_name(user_id)
  # end

  # defp handle_db_response(%ContactPlane.Vk.User{user_id: _, name: name}, _), do: name

  # defp get_name(user_id) do
  #   ContactPlane.Repo.get_by(ContactPlane.Vk.User, user_id: user_id)
  #   |> handle_db_response(user_id)
  # end

  # def handle_event([type, msg_id, _, @vk_chat, _, _, _, _])
  #     when type in [3, 4, 5, 18] do
  #   res =
  #     ContactPlane.Vk.invoke(
  #       "messages.getById",
  #       %{message_ids: "#{msg_id}"}
  #     )

  #   case res do
  #     {:ok, %{"response" => %{"items" => [message]}}} ->
  #       Logger.debug("Received vk message: #{inspect(message)}")
  #       message |> handle_event()

  #     {:error, err} ->
  #       Logger.emergency("Error while fetching data about message from vk: #{inspect(err)}")
  #   end
  # end


end
