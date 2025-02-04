defmodule ContactPlane.Repo do
  use Ecto.Repo,
    otp_app: :contact_plane,
    adapter: Ecto.Adapters.SQLite3
end
