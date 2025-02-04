defmodule ContactPlane.Repo.Migrations.Users do
  use Ecto.Migration

  def change do
    create table(:vk_users) do
      add(:user_id, :integer, unique: true)
      add(:name, :string, default: "<>")
    end

    create table(:tg_users) do
      add(:user_id, :integer, unique: true)
      add(:name, :string, default: "<>")
    end
  end
end
