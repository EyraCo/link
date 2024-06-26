defmodule Systems.Storage.BuiltIn.Backend do
  @behaviour Systems.Storage.Backend

  require Logger

  alias Systems.Storage.BuiltIn

  @impl true
  def store(%{"key" => folder}, data, meta_data) do
    filename = filename(meta_data)
    special().store(folder, filename, data)
  end

  @impl true
  def store(_, _, _) do
    {:error, :endpoint_key_missing}
  end

  @impl true
  def list_files(%{key: folder}) do
    special().list_files(folder)
  end

  defp filename(%{"identifier" => identifier}) do
    identifier
    |> Enum.map_join("_", fn [key, value] -> "#{key}=#{value}" end)
    |> then(&"#{&1}.json")
  end

  defp settings do
    Application.fetch_env!(:core, Systems.Storage.BuiltIn)
  end

  defp special do
    # Allow mocking
    Access.get(settings(), :special, BuiltIn.LocalFS)
  end
end
