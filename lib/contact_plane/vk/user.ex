defmodule ContactPlane.Vk.User do
  @moduledoc false

  use Ecto.Schema

  schema "vk_users" do
    field(:user_id, :string)
    field(:name, :string)
  end
end
