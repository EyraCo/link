defmodule Systems.Assignment.ContentPageForm do
  use CoreWeb, :live_component

  alias Frameworks.Pixel
  alias Systems.Assignment
  alias Systems.Content

  @impl true
  def update(
        %{
          id: id,
          assignment: assignment,
          page_key: page_key,
          opt_in?: opt_in?,
          on_text: on_text,
          off_text: off_text
        },
        socket
      ) do
    confirming_status_off = Map.get(socket.assigns, :confirming_status_off, false)

    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        page_key: page_key,
        opt_in?: opt_in?,
        on_text: on_text,
        off_text: off_text,
        confirming_status_off: confirming_status_off
      )
      |> update_page_ref()
      |> update_status()
      |> compose_child(:switch)
      |> compose_child(:content_page_form)
    }
  end

  def update_page_ref(
        %{assigns: %{assignment: %{page_refs: page_refs}, page_key: page_key}} = socket
      ) do
    page_ref = Enum.find(page_refs, &(&1.key == page_key))
    socket |> assign(page_ref: page_ref)
  end

  def update_status(%{assigns: %{confirming_status_off: true}} = socket) do
    socket |> assign(status: :off)
  end

  def update_status(%{assigns: %{page_ref: page_ref}} = socket) do
    status =
      if page_ref do
        :on
      else
        :off
      end

    socket |> assign(status: status)
  end

  @impl true
  def compose(:switch, %{
        opt_in?: opt_in?,
        on_text: on_text,
        off_text: off_text,
        status: status
      }) do
    %{
      module: Pixel.Switch,
      params: %{
        opt_in?: opt_in?,
        on_text: on_text,
        off_text: off_text,
        status: status
      }
    }
  end

  @impl true
  def compose(:confirmation_modal, %{page_ref: page_ref}) do
    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: %{
          page_ref: page_ref
        }
      }
    }
  end

  @impl true
  def compose(:content_page_form, %{page_ref: nil}) do
    nil
  end

  @impl true
  def compose(:content_page_form, %{page_ref: %{page: page}}) do
    %{
      module: Content.PageForm,
      params: %{
        entity: page
      }
    }
  end

  @impl true
  def handle_event(
        "update",
        %{status: :on},
        %{assigns: %{assignment: assignment, page_key: page_key}} = socket
      ) do
    {:ok, %{assignment_page_ref: page_ref}} =
      Assignment.Public.create_page_ref(assignment, page_key)

    {
      :noreply,
      socket
      |> assign(page_ref: page_ref)
      |> compose_child(:content_page_form)
    }
  end

  @impl true
  def handle_event("update", %{status: :off}, socket) do
    if socket.assigns.page_ref.page.body != nil do
      {
        :noreply,
        socket
        |> update_switch(confirming_status_off: true)
        |> compose_child(:confirmation_modal)
        |> show_modal(:confirmation_modal, :dialog)
      }
    else
      {:ok, _} = Assignment.Public.delete_page_ref(socket.assigns.page_ref)
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancelled", %{source: %{name: :confirmation_modal}}, socket) do
    {:noreply,
     socket
     |> update_switch(confirming_status_off: false)
     |> hide_modal(:confirmation_modal)}
  end

  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :confirmation_modal}},
        %{assigns: %{page_ref: page_ref}} = socket
      ) do
    {:ok, _} = Assignment.Public.delete_page_ref(page_ref)

    {
      :noreply,
      socket
      |> assign(confirming_status_off: false)
      |> hide_modal(:confirmation_modal)
    }
  end

  @impl true
  def handle_modal_closed(socket, :confirmation_modal) do
    update_switch(socket, confirming_status_off: false)
  end

  defp update_switch(socket, confirming_status_off: confirming_status_off) do
    socket
    |> assign(confirming_status_off: confirming_status_off)
    |> update_status()
    |> compose_child(:switch)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.child name={:switch} fabric={@fabric} />
        <.spacing value="S" />
        <.child name={:content_page_form} fabric={@fabric} />
      </div>
    """
  end
end
