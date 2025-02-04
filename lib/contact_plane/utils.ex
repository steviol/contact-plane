defmodule ContactPlane.Utils do
  @moduledoc false

  @doc """
  Wrapper for Kernel.inspect/1 which passes `pretty: :true` by default
  """
  def inspect(x, opts \\ []) do
    "#{Kernel.inspect(x, opts ++ [pretty: :true])}"
  end
end
