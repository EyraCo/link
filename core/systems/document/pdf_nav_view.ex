defmodule Systems.Document.PDFNavView do
  use CoreWeb, :live_component
  import Frameworks.Pixel.Line

  alias Systems.Document

  @impl true
  def update(%{key: key, title: title, url: url} = params, socket) do
    visible = Map.get(params, :visible, true)

    {
      :ok,
      socket
      |> assign(key: key, title: title, url: url, visible: visible)
      |> update_state()
      |> compose_element(:ready_button)
      |> compose_child(:pdf_view)
    }
  end

  defp update_state(%{assigns: %{visible: visible}} = socket) do
    state =
      if visible do
        "visible"
      else
        "hidden"
      end

    assign(socket, state: state)
  end

  @impl true
  def compose(:ready_button, %{myself: myself}) do
    %{
      action: %{type: :send, event: "complete", target: myself},
      face: %{
        type: :primary,
        bg_color: "bg-success",
        label: dgettext("eyra-document", "ready.button")
      }
    }
  end

  @impl true
  def compose(:pdf_view, %{key: key, url: url, visible: visible}) do
    %{
      module: Document.PDFView,
      params: %{
        key: key,
        url: url,
        visible: visible,
        title: dgettext("eyra-assignment", "privacy.title")
      }
    }
  end

  @impl true
  def handle_event("complete", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def render(assigns) do
    ~H"""

    <div class="flex flex-row w-full h-full justify-center" >
      <div class="flex-grow"/>
      <div class="w-full h-full max-w-[1200px] p-4 lg:p-8 ">
        <div class="w-full">
          <div
            class="flex flex-row items-center w-full gap-4"
            data-state={@state}
          >
            <Text.title2 margin=""><%= @title %></Text.title2>
            <div class="flex-grow"/>
          </div>
          <.spacing value="M" />
          <.line />
          <div class="flex flex-col w-full h-full">
            <div>
              <.child name={:pdf_view} fabric={@fabric} />
            </div>
            <.spacing value="M" />
            <div class="flex flex-row-reverse w-full ">
              <div class="w-1/6">
                <Button.dynamic {@ready_button} />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="flex-grow"/>
    </div>
    """
  end
end
