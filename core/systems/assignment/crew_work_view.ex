defmodule Systems.Assignment.CrewWorkView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Line

  require Logger

  alias Frameworks.Concept
  alias Frameworks.Signal

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow
  alias Systems.Content
  alias Systems.Consent
  alias Systems.Document

  def update(
        %{
          work_items: work_items,
          privacy_doc: privacy_doc,
          consent_agreement: consent_agreement,
          context_menu_items: context_menu_items,
          intro_page_ref: intro_page_ref,
          support_page_ref: support_page_ref,
          crew: crew,
          user: user,
          timezone: timezone,
          panel_info: %{embedded?: embedded?} = panel_info,
          tester?: tester?
        },
        socket
      ) do
    retry? = Map.get(socket.assigns, :retry?, false)
    tool_started = Map.get(socket.assigns, :tool_started, false)
    tool_initialized = Map.get(socket.assigns, :tool_initialized, false)
    initial? = Map.get(socket.assigns, :work_items) == nil
    tasks_finished? = tasks_finished?(work_items)

    socket =
      socket
      |> assign(
        work_items: work_items,
        privacy_doc: privacy_doc,
        consent_agreement: consent_agreement,
        context_menu_items: context_menu_items,
        intro_page_ref: intro_page_ref,
        support_page_ref: support_page_ref,
        crew: crew,
        user: user,
        timezone: timezone,
        tester?: tester?,
        panel_info: panel_info,
        tool_started: tool_started,
        tool_initialized: tool_initialized,
        retry?: retry?
      )

    socket =
      if initial? do
        if tasks_finished? and not embedded? do
          socket |> finish()
        else
          socket |> initialize()
        end
      else
        socket |> update()
      end

    {:ok, socket}
  end

  defp finish(socket) do
    socket
    |> compose_child(:context_menu)
    |> compose_child(:finished_view)
  end

  defp initialize(socket) do
    socket
    |> hide_child(:finished_view)
    |> hide_modal(:tool_ref_view)
    |> compose_child(:context_menu)
    |> update_selected_item_id()
    |> update_selected_item()
  end

  defp update(socket) do
    socket
    |> update_child(:context_menu)
    |> update_child(:work_list_view)
    |> update_child(:start_view)
    |> update_child(:tool_ref_view)
  end

  defp tasks_finished?(work_items) do
    task_ids = Enum.map(work_items, fn {_, task} -> task.id end)
    Crew.Public.tasks_finished?(task_ids)
  end

  defp tool_visible?(%{assigns: assigns} = _socket) do
    tool_visible?(assigns)
  end

  defp tool_visible?(%{tool_started: tool_started, tool_initialized: tool_initialized}) do
    tool_started and tool_initialized
  end

  defp compose_tool_ref_view(%{assigns: %{selected_item_id: selected_item_id}} = socket) do
    case Fabric.get_child(socket, :tool_ref_view) do
      %{params: %{work_item: {%{id: id}, _}}} when id == selected_item_id ->
        socket

      _ ->
        socket
        |> compose_child(:tool_ref_view)
        |> prepare_modal_tool_ref_view_if_needed()
    end
  end

  defp update_selected_item_id(
         %{assigns: %{work_items: work_items, selected_item_id: selected_item_id}} = socket
       )
       when not is_nil(selected_item_id) do
    if Enum.find(work_items, fn {%{id: id}, _} -> id == selected_item_id end) do
      socket
    else
      socket
      |> assign(selected_item_id: nil)
      |> update_selected_item_id()
    end
  end

  defp update_selected_item_id(%{assigns: %{work_items: []}} = socket) do
    socket |> assign(selected_item_id: nil)
  end

  defp update_selected_item_id(%{assigns: %{work_items: work_items}} = socket) do
    {%{id: selected_item_id}, _} =
      Enum.find(work_items, List.first(work_items), fn {_, %{status: status}} ->
        status == :pending
      end)

    socket |> assign(selected_item_id: selected_item_id)
  end

  defp update_selected_item(
         %{assigns: %{selected_item_id: selected_item_id, work_items: work_items}} = socket
       ) do
    selected_item = Enum.find(work_items, fn {%{id: id}, _} -> id == selected_item_id end)

    socket
    |> assign(
      selected_item: selected_item,
      tool_initialized: false,
      tool_started: false
    )
    |> compose_child(:work_list_view)
    |> compose_child(:start_view)
    |> compose_tool_ref_view()
  end

  # Compose

  @impl true
  def compose(
        :start_view,
        %{
          selected_item: selected_item,
          tool_started: tool_started,
          tool_initialized: tool_initialized,
          crew: crew,
          user: user
        } = assigns
      )
      when not is_nil(selected_item) do
    # In case of an external panel, the particiant id given by the panel should be forwarded to external systems
    participant =
      if participant = get_in(assigns, [:panel_info, :participant]) do
        participant
      else
        %{public_id: participant} = Crew.Public.member(crew, user)
        participant
      end

    %{
      module: Assignment.StartView,
      params: %{
        participant: participant,
        work_item: selected_item,
        loading: tool_started and not tool_initialized
      }
    }
  end

  @impl true
  def compose(:start_view, _assigns), do: nil

  @impl true
  def compose(:work_list_view, %{
        work_items: [_one, _two | _] = work_items,
        selected_item_id: selected_item_id
      })
      when not is_nil(selected_item_id) do
    work_list = %{
      items: Enum.map(work_items, &map_item/1),
      selected_item_id: selected_item_id
    }

    %{module: Workflow.WorkListView, params: %{work_list: work_list}}
  end

  @impl true
  def compose(:work_list_view, _assigns), do: nil

  @impl true
  def compose(
        :tool_ref_view,
        %{
          user: user,
          timezone: timezone,
          launcher: %{module: _, params: _},
          selected_item: {%{title: title, tool_ref: tool_ref}, task}
        } = assigns
      ) do
    %{
      module: Workflow.ToolRefView,
      params: %{
        title: title,
        tool_ref: tool_ref,
        task: task,
        visible: tool_visible?(assigns),
        user: user,
        timezone: timezone
      }
    }
  end

  @impl true
  def compose(:tool_ref_view, %{launcher: _}) do
    nil
  end

  @impl true
  def compose(
        :tool_ref_view,
        %{selected_item: selected_item} = assigns
      ) do
    launcher = launcher(selected_item)
    compose(:tool_ref_view, Map.put(assigns, :launcher, launcher))
  end

  @impl true
  def compose(:tool_ref_view, _assigns), do: nil

  def compose(:context_menu, %{context_menu_items: []}) do
    nil
  end

  def compose(:context_menu, %{context_menu_items: context_menu_items}) do
    %{
      module: Content.ContextMenu,
      params: %{
        items: context_menu_items
      }
    }
  end

  def compose(:intro_page, %{intro_page_ref: %{page: page}}) do
    %{
      module: Content.PageView,
      params: %{
        title: dgettext("eyra-assignment", "intro.page.title"),
        page: page
      }
    }
  end

  def compose(:privacy_page, %{privacy_doc: %{ref: ref}}) do
    %{
      module: Document.PDFView,
      params: %{
        key: "privacy_doc_view",
        url: ref,
        title: dgettext("eyra-assignment", "privacy.title")
      }
    }
  end

  def compose(:consent_page, %{consent_agreement: consent_agreement, user: user}) do
    %{
      module: Consent.SignatureView,
      params: %{
        title: dgettext("eyra-consent", "signature.view.title"),
        signature: Consent.Public.get_signature(consent_agreement, user)
      }
    }
  end

  def compose(:support_page, %{support_page_ref: %{page: page}}) do
    %{
      module: Content.PageView,
      params: %{
        title: dgettext("eyra-assignment", "support.page.title"),
        page: page
      }
    }
  end

  def compose(:finished_view, _) do
    %{
      module: Assignment.FinishedView,
      params: %{
        title: dgettext("eyra-assignment", "finished_view.title")
      }
    }
  end

  # Events

  def handle_event("retry", _, socket) do
    {
      :noreply,
      socket
      |> assign(retry?: true)
      |> hide_child(:finished_view)
      |> initialize()
    }
  end

  def handle_event("tool_initialized", _, socket) do
    {
      :noreply,
      socket
      |> assign(tool_initialized: true)
      |> show_tool_ref_view_if_needed()
    }
  end

  @impl true
  def handle_event("cancel_task", _payload, socket) do
    {
      :noreply,
      socket
      |> assign(
        tool_started: false,
        tool_initialized: false
      )
      |> hide_modal(:tool_ref_view)
      |> compose_child(:start_view)
      |> compose_tool_ref_view()
    }
  end

  @impl true
  def handle_event("complete_task", _, socket) do
    {
      :noreply,
      socket
      |> handle_complete_task()
    }
  end

  @impl true
  def handle_event(
        "work_item_selected",
        %{"item" => item_id},
        socket
      ) do
    item_id = String.to_integer(item_id)

    {
      :noreply,
      socket
      |> assign(selected_item_id: item_id)
      |> update_selected_item()
    }
  end

  @impl true
  def handle_event("start", _, %{assigns: %{selected_item: selected_item}} = socket) do
    {
      :noreply,
      socket
      |> assign(tool_started: true)
      |> compose_child(:start_view)
      |> show_tool_ref_view_if_needed()
      |> start_task(selected_item)
    }
  end

  @impl true
  def handle_event("feldspar_event", event, socket) do
    {
      :noreply,
      socket |> handle_feldspar_event(event)
    }
  end

  @impl true
  def handle_event("show", %{page: :privacy}, socket) do
    {
      :noreply,
      socket
      |> compose_child(:privacy_page)
      |> show_modal(:privacy_page, :page)
    }
  end

  @impl true
  def handle_event("show", %{page: :consent}, socket) do
    {
      :noreply,
      socket
      |> compose_child(:consent_page)
      |> show_modal(:consent_page, :page)
    }
  end

  @impl true
  def handle_event("show", %{page: :assignment_information}, socket) do
    {
      :noreply,
      socket
      |> compose_child(:intro_page)
      |> show_modal(:intro_page, :page)
    }
  end

  @impl true
  def handle_event("show", %{page: :assignment_helpdesk}, socket) do
    {
      :noreply,
      socket
      |> compose_child(:support_page)
      |> show_modal(:support_page, :page)
    }
  end

  @impl true
  def handle_modal_closed(socket, :tool_ref_view) do
    socket |> update_selected_item()
  end

  def handle_modal_closed(socket, name) do
    Logger.debug("unhandled modal closed event for: #{name}")
    socket
  end

  # Private

  defp prepare_modal_tool_ref_view_if_needed(%{assigns: %{fabric: fabric}} = socket) do
    if Fabric.exists?(fabric, :tool_ref_view) do
      if prepared_modal?(fabric, :prepared_modal) do
        socket |> assign(tool_initialized: true)
      else
        socket |> prepare_modal(:tool_ref_view, :full)
      end
    else
      Logger.warning("No tool ref view found to prepare modal")
      socket
    end
  end

  defp show_tool_ref_view_if_needed(
         %{assigns: %{tool_started: tool_started, tool_initialized: tool_initialized}} = socket
       ) do
    if tool_started and tool_initialized do
      socket
      |> compose_child(:tool_ref_view)
      |> show_modal(:tool_ref_view, :full)
      |> compose_child(:start_view)
    else
      socket
    end
  end

  defp handle_feldspar_event(
         socket,
         %{
           "__type__" => "CommandSystemExit",
           "code" => code,
           "info" => info
         }
       ) do
    if code == 0 do
      handle_complete_task(socket)
    else
      Frameworks.Pixel.Flash.put_info(
        socket,
        "Application stopped unexpectedly [#{code}]: #{info}"
      )
    end
  end

  defp handle_feldspar_event(
         %{assigns: %{selected_item: {%{id: task, group: group}, _}}} = socket,
         %{
           "__type__" => "CommandSystemDonate",
           "key" => key,
           "json_string" => json_string
         }
       ) do
    socket
    |> send_event(:parent, "store", %{task: task, key: key, group: group, data: json_string})
    |> Frameworks.Pixel.Flash.put_info("Donated")
  end

  defp handle_feldspar_event(socket, %{
         "__type__" => "CommandSystemEvent",
         "name" => "initialized"
       }) do
    socket
    |> assign(tool_initialized: true)
    |> show_tool_ref_view_if_needed()
  end

  defp handle_feldspar_event(socket, %{"__type__" => type}) do
    socket |> Frameworks.Pixel.Flash.put_error("Unsupported event " <> type)
  end

  defp handle_feldspar_event(socket, _) do
    socket |> Frameworks.Pixel.Flash.put_error("Unsupported event")
  end

  defp handle_complete_task(%{assigns: %{selected_item: {_, task}}} = socket) do
    {:ok, %{crew_task: updated_task}} = Crew.Public.complete_task(task)

    if embedded?(socket) and singleton?(socket) do
      # Keep tool_ref view open and prevent finished view from being shown
      # FIXME: This is a temporary solution to allow embeds to work https://github.com/eyra/mono/issues/997
      socket
    else
      socket
      |> update_task(updated_task)
      |> hide_modal(:tool_ref_view)
      |> handle_finished_state()
      |> select_next_item()
    end
  end

  defp update_task(%{assigns: %{work_items: work_items}} = socket, updated_task) do
    work_items =
      Enum.map(work_items, fn {item, task} ->
        if task.id == updated_task.id do
          {item, updated_task}
        else
          {item, task}
        end
      end)

    assign(socket, work_items: work_items)
  end

  defp select_next_item(%{assigns: %{work_items: work_items}} = socket)
       when length(work_items) <= 1 do
    socket
  end

  defp select_next_item(socket) do
    socket
    |> select_next_item_id()
    |> update_selected_item()
  end

  defp select_next_item_id(
         %{assigns: %{work_items: work_items, selected_item_id: selected_item_id}} = socket
       ) do
    next_index =
      if index = Enum.find_index(work_items, fn {%{id: id}, _} -> id == selected_item_id end) do
        rem(index + 1, Enum.count(work_items))
      else
        0
      end

    {%{id: selected_item_id}, _} = Enum.at(work_items, next_index)

    socket |> assign(selected_item_id: selected_item_id)
  end

  defp handle_finished_state(%{assigns: %{retry?: true}} = socket), do: socket

  defp handle_finished_state(%{assigns: %{work_items: work_items}} = socket) do
    if tasks_finished?(work_items) do
      socket
      |> signal_tasks_finished()
      |> compose_child(:finished_view)
    else
      socket
    end
  end

  defp signal_tasks_finished(%{assigns: %{tester?: true}} = socket) do
    socket
  end

  defp signal_tasks_finished(%{assigns: %{crew: crew, user: user}} = socket) do
    %Crew.MemberModel{} = crew_member = Crew.Public.get_member(crew, user)
    Signal.Public.dispatch!({:crew_member, :finished_tasks}, %{crew_member: crew_member})
    socket
  end

  defp map_item({%{id: id, title: title, group: group}, task}) do
    %{id: id, title: title, icon: group, status: task_status(task)}
  end

  defp task_status(%{status: status}), do: status
  defp task_status(_), do: :pending

  defp start_task(socket, {_, task}) do
    start_task(socket, task)
  end

  defp start_task(socket, task) do
    Crew.Public.start_task(task)
    socket
  end

  defp launcher({%{tool_ref: tool_ref}, _}) do
    tool_ref
    |> Workflow.ToolRefModel.tool()
    |> Concept.ToolModel.launcher()
  end

  defp embedded?(%{assigns: %{panel_info: %{embedded?: embedded?}}}) do
    embedded?
  end

  defp singleton?(%{assigns: %{work_items: work_items}}) do
    length(work_items) == 1
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div class="w-full h-full flex flex-row">
        <%= if exists?(@fabric, :finished_view) do %>
          <.child name={:finished_view} fabric={@fabric} />
        <% else %>
          <%= if exists?(@fabric, :work_list_view) do %>
            <div class="w-left-column flex-shrink-0 flex flex-col py-6 gap-6">
              <div class="px-6">
                <Text.title2 margin=""><%= dgettext("eyra-assignment", "work.list.title") %></Text.title2>
              </div>
              <div>
                <.line />
              </div>
              <div class="flex-grow">
                <div class="px-6 h-full overflow-y-scroll">
                  <.child name={:work_list_view} fabric={@fabric} />
                </div>
              </div>
            </div>
            <div class="border-l border-grey4">
            </div>
          <% end %>

          <div class="h-full w-full">
            <.child name={:start_view} fabric={@fabric} />
          </div>
        <% end %>

        <%!-- floating button --%>
        <.child name={:context_menu} fabric={@fabric} />
      </div>
    """
  end
end
