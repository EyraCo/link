defmodule Systems.Workflow.ToolRefView do
  use CoreWeb, :live_component

  require Logger

  alias Frameworks.Concept
  alias Systems.Workflow

  def update(
        %{
          id: id,
          title: title,
          tool_ref: tool_ref,
          task: task,
          visible: visible,
          user: user,
          timezone: timezone
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        tool_ref: tool_ref,
        task: task,
        visible: visible,
        user: user,
        timezone: timezone
      )
      |> reset_fabric()
      |> update_launcher()
    }
  end

  def update_launcher(%{assigns: %{tool_ref: tool_ref}} = socket) do
    launcher =
      tool_ref
      |> Workflow.ToolRefModel.tool()
      |> Concept.ToolModel.launcher()

    socket |> update_launcher(launcher)
  end

  def update_launcher(
        %{
          assigns: %{
            tool_ref: %{id: id},
            user: user,
            timezone: timezone,
            title: title,
            visible: visible
          }
        } = socket,
        %{module: module, params: params}
      ) do
    params = Map.merge(params, %{user: user, timezone: timezone, title: title, visible: visible})
    child = Fabric.prepare_child(socket, "tool_ref_#{id}", module, params)
    socket |> show_child(child)
  end

  def update_launcher(socket, _) do
    # This use case is supported for preview mode
    tool_ref = Map.get(socket.assigns, :tool_ref)
    Logger.warning("No module launcher found for #{inspect(tool_ref)}")
    socket
  end

  @impl true
  def handle_event("complete_task", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def handle_event("cancel_task", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "cancel_task")}
  end

  @impl true
  def handle_event("tool_initialized", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "tool_initialized")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="tool-ref-view w-full h-full">
      <.stack fabric={@fabric} />
    </div>
    """
  end
end
