defmodule Systems.Consent.SignatureView do
  use CoreWeb, :live_component

  @impl true
  def update(%{signature: signature}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
      |> assign(signature: signature)
      |> compose_element(:source)
    }
  end

  @impl true
  def compose(:source, %{signature: %{revision: %{source: source}}}), do: source
  def compose(:source, _), do: ""

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full h-full">
        <div class="wysiwyg">
          <%= raw @source %>
        </div>
      </div>
    """
  end
end
