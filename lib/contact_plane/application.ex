defmodule ContactPlane.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ContactPlane.Vk.Listener,
      ContactPlane.Tg.Listener,
      ContactPlane.Repo
    ]

    opts = [strategy: :one_for_one, name: ContactPlane.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
