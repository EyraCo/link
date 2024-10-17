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
    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        page_key: page_key,
        opt_in?: opt_in?,
        on_text: on_text,
        off_text: off_text
      )
      |> update_page_ref()
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

  @impl true
  def compose(:switch, %{
        page_ref: page_ref,
        opt_in?: opt_in?,
        on_text: on_text,
        off_text: off_text
      }) do
    %{
      module: Pixel.Switch,
      params: %{
        opt_in?: opt_in?,
        on_text: on_text,
        off_text: off_text,
        status:
          if page_ref do
            :on
          else
            :off
          end
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
    page_ref = Assignment.Public.create_page_ref(assignment, page_key)

    {
      :noreply,
      socket
      |> assign(page_ref: page_ref)
      |> update_child(:content_page_form)
    }
  end

  @impl true
  def handle_event("update", %{status: :off}, socket) do
    if socket.assigns.page_ref.page.body != nil do
      {
        :noreply,
        socket
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
     |> hide_modal(:confirmation_modal)}
  end

  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :confirmation_modal}},
        %{assigns: %{page_ref: page_ref}} = socket
      ) do
    {:ok, _} = Assignment.Public.delete_page_ref(page_ref)
    {:noreply, socket |> hide_modal(:confirmation_modal)}
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
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
