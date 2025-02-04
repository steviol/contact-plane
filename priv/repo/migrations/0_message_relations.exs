defmodule ContactPlane.Repo.Migrations.MessageRelations do
  use Ecto.Migration

  def change do
    create table(:message_relations) do
      add(:vk_message_id, :integer)
      add(:tg_message_id, :integer)
    end
  end
end
