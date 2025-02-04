defmodule ContactPlane.Vk do
  @moduledoc """
  wrapper for vk
  """

  use Tesla

  require Logger

  alias ContactPlane.Utils

  @token Application.compile_env(:contact_plane, :vk_token)
  @v Application.compile_env(:contact_plane, :vk_api_ver)

  plug(Tesla.Middleware.BaseUrl, "https://api.vk.com/method/")
  plug(Tesla.Middleware.Query, access_token: @token, v: @v)
  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.JSON)

  def invoke(method, params \\ %{}) do
    rid =
      Enum.random(0..18_446_744_073_709_551_615)
      |> Integer.to_string()
      |> String.pad_leading(8, "0")
      |> then(fn id -> "0x" <> id end)

    Logger.debug("""
    Request id: #{rid}
    Invoking VK API method #{method} with params #{Utils.inspect(params)}
    """)

    params = params |> Enum.map(fn {k, v} -> {k, v} end)

    res = ContactPlane.Vk.get(method, query: params)

    case res do
      {:ok, %{body: body}} ->
        Logger.debug("""
        Request id: #{rid}
        VK API response: #{Utils.inspect(body)}
        """)

        {:ok, body}

      {:error, err} ->
        Logger.error("""
        Request id: #{rid}
        HTTP error while accessing VK API: #{Utils.inspect(err)}
        """)

        {:error, err}
    end
  end
end
