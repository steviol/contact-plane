defmodule ContactPlane.Tg do
  @moduledoc """
  Tesla telegram API wrapper
  """

  use Tesla

  require Logger

  alias ContactPlane.Utils

  @token Application.compile_env(:contact_plane, :tg_token)

  plug(Tesla.Middleware.BaseUrl, "https://api.telegram.org/bot#{@token}/")
  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.JSON)

  def dl(file_id) do
    {:ok, %{"result" => %{"file_path" => file_path}}} = invoke("getFile", %{file_id: file_id})

    {:ok, %{body: body}} =
      request(
        method: :get,
        url: "https://api.telegram.org/file/bot#{@token}/#{file_path}"
      )

    body
  end

  @doc """
  Invokes `method` with given `params`. Also creates some useful logs and
  handles some errors
  """
  def invoke(method, params \\ %{}) do
    rid =
      Enum.random(0..18_446_744_073_709_551_615)
      |> Integer.to_string()
      |> String.pad_leading(8, "0")
      |> then(fn id -> "0x" <> id end)

    Logger.debug("""
    Request id: #{rid}
    Invoking TG API method: #{method}
               with params: #{Utils.inspect(params)}
    """)

    res =
      request(
        method: :post,
        url: method,
        body: params |> URI.encode_query(),
        headers: [{"Content-Type", "application/x-www-form-urlencoded"}]
      )

    case res do
      {:ok, %{status: 200, body: body}} ->
        Logger.debug("""
        Request id: #{rid}
        Tg API response: #{Utils.inspect(body)}
        """)

        {:ok, body}

      {:ok, res} ->
        Logger.error("""
        Request id: #{rid}
        Tg API returned error: #{Utils.inspect(res)}
        """)

        {:error, res}

      {:error, err} ->
        Logger.error("""
        Request id: #{rid}
        HTTP error while accessing Tg API: #{Utils.inspect(err)}
        """)

        {:error, err}
    end
  end
end
