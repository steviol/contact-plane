defmodule ContactPlane.Message do
  @moduledoc false

  use Ecto.Schema

  schema "message_relations" do
    field(:vk_message_id, :integer)
    field(:tg_message_id, :integer)
  end
end
