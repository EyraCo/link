defmodule Systems.Assignment.CrewPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Composer
  use Frameworks.Pixel.ModalView

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Viewport, __MODULE__})

  require Logger

  alias Core.ImageHelpers
  alias Frameworks.Pixel.Hero
  alias Frameworks.Signal

  alias Systems.Assignment
  alias Systems.Project
  alias Systems.Storage

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    %{crew: crew} = Assignment.Public.get!(String.to_integer(id), [:crew])
    crew
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Assignment.Public.get!(id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(%{"id" => id}, session, socket) do
    String.to_integer(id)
    |> Assignment.Public.get!([:info])
    |> Assignment.Model.language()
    |> CoreWeb.Live.Hook.Locale.put_locale()

    {
      :ok,
      socket
      |> assign(
        id: id,
        image_info: nil,
        panel_form: nil
      )
      |> update_panel_info(session)
      |> update_image_info()
      |> signal_started()
      |> update_flow()
    }
  end

  @impl true
  def compose(:declined_view, _) do
    %{
      module: Assignment.DeclinedView,
      params: %{}
    }
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
    |> update_flow()
    |> update_image_info()
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_image_info()
  end

  def signal_started(%{assigns: %{vm: %{crew_member: crew_member}}} = socket) do
    Signal.Public.dispatch!({:crew_member, :started}, %{crew_member: crew_member})
    socket
  end

  defp update_image_info(
         %{assigns: %{viewport: %{"width" => viewport_width}, vm: %{info: %{image_id: image_id}}}} =
           socket
       ) do
    image_width = viewport_width
    image_height = 360
    image_info = ImageHelpers.get_image_info(image_id, image_width, image_height)

    socket
    |> assign(image_info: image_info)
  end

  defp update_image_info(socket) do
    socket
  end

  defp update_panel_info(socket, %{"panel_info" => panel_info}) do
    assign(socket, panel_info: panel_info)
  end

  defp update_panel_info(socket, _) do
    assign(socket, panel_info: nil)
  end

  defp update_flow(%{assigns: %{vm: %{flow: flow}}} = socket) do
    socket |> install_children(flow)
  end

  def handle_info({:complete_task, _}, socket) do
    {:noreply, socket |> send_event(:flow, "complete_task")}
  end

  #
  # Used in Systems.Storage.Centerdata.Backend to post data to Centerdata and handle the response in-browser.
  # This is een temp solution before better integrating the donation protocol with Centerdata
  #
  def handle_info(%{storage_event: %{panel: _, form: form}}, socket) do
    {:noreply, socket |> show_panel_form(form)}
  end

  @impl true
  def handle_event("continue", %{source: source}, socket) do
    {:noreply, socket |> show_next(source)}
  end

  @impl true
  def handle_event("accept", %{source: source}, socket) do
    {:noreply, socket |> show_next(source)}
  end

  @impl true
  def handle_event(
        "decline",
        _payload,
        %{assigns: %{model: model, current_user: user, panel_info: %{embedded?: embedded?}}} =
          socket
      ) do
    Assignment.Public.decline_member(model, user)
    socket = store(socket, "", "", "onboarding", "{\"status\":\"consent declined\"}")

    socket =
      if embedded? do
        socket
      else
        socket
        |> compose_child(:declined_view)
        |> show_modal(:declined_view, :notification)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("store", %{task: task, key: key, group: group, data: data}, socket) do
    {:noreply, socket |> store(task, key, group, data)}
  end

  @impl true
  def handle_event(name, event, socket) do
    Logger.debug("[CrewPage] Forwarding event to flow: #{name}")

    {
      :noreply,
      socket |> send_event(:flow, name, event)
    }
  end

  def store(
        %{
          assigns: %{
            panel_info: panel_info,
            model: assignment,
            remote_ip: remote_ip
          }
        } = socket,
        task,
        key,
        group,
        data
      ) do
    participant = Map.get(panel_info, :participant, "")

    meta_data = %{
      remote_ip: remote_ip,
      panel_info: panel_info,
      identifier: [
        [:assignment, assignment.id],
        [:task, task],
        [:participant, participant],
        [:source, group],
        [:key, key]
      ]
    }

    with {:ok, storage_endpoint} <- Project.Public.get_storage_endpoint_by(assignment),
         {:ok, storage_info} <- Storage.Private.storage_info(storage_endpoint, assignment) do
      Storage.Public.store(storage_endpoint, storage_info, data, meta_data)
      socket
    else
      _ ->
        message = dgettext("eyra-assignment", "storage.not_available.warning")
        Logger.error(message)
        socket |> put_flash(:error, message)
    end
  end

  defp show_panel_form(socket, %{module: module, params: params}) do
    panel_form = prepare_child(socket, :panel_form, module, params)
    socket |> assign(panel_form: Map.from_struct(panel_form))
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped menus={@menus} footer?={false}>
        <:header>
          <div class="h-[180px] bg-grey5">
          <%= if @image_info do %>
            <Hero.image_banner title={@vm.info.title} subtitle={@vm.info.subtitle} logo_url={@vm.info.logo_url} image_info={@image_info} />
          <% end %>
          </div>
        </:header>

        <ModalView.dynamic modals={@modals} />

        <%!-- hidden auto submit form --%>
        <%= if @panel_form do %>
          <div class="relative">
            <div class="absolute hidden">
              <.live_child {@panel_form} />
            </div>
          </div>
        <% end %>

        <div id={:crew_page} class="w-full h-full flex flex-col" phx-hook="Viewport">
          <.flow fabric={@fabric} />
        </div>
      </.stripped>
    """
  end
end
