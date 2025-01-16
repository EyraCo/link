defmodule Fabric do
  @type assigns :: map()
  @type composition_id :: atom() | binary()
  @type composition :: child() | element()
  @type child :: %{module: module(), params: map()}
  @type element :: map() | binary() | number()
  @type socket :: Phoenix.LiveView.Socket.t()

  @callback compose(id :: composition_id(), a :: assigns()) :: composition() | nil
  @callback handle_modal_closed(socket(), any()) :: socket()

  @optional_callbacks handle_modal_closed: 2

  # although colons and periods are formaly supported, they seem cause errors when calling 'querySelectorAll' on 'Document': '#item_cell_44::system::-PID-0-24547-1-_item_form_group' is not a valid selector.
  # Example: dom.js:39 Uncaught DOMException: Failed to execute 'querySelectorAll' on 'Document': '#item_cell_44::workflow::page_item_form_group' is not a valid selector.
  @html_id_invalid ~r"[^A-Za-z0-9_-]"
  @html_id_seperator "__"
  @html_id_replacement "-"

  require Logger

  defmacro __using__(_opts) do
    quote do
      @behaviour Fabric

      import Fabric
      import Fabric.Html

      require Logger

      def update(
            %{
              fabric_event: %{name: :handle_modal_closed, payload: %{live_component: %{ref: ref}}}
            },
            %{assigns: %{fabric: fabric}} = socket
          ) do
        # Sent from Fabric.handle_modal_closed/2 indicating this live component has been closed as a modal view. Notify the parent.
        {:ok, socket |> send_event(:parent, :handle_modal_closed)}
      end

      def update(
            %{fabric_event: %{name: :handle_modal_closed, payload: %{source: %{name: name}}}},
            %{assigns: %{fabric: fabric}} = socket
          ) do
        socket =
          if function_exported?(__MODULE__, :handle_modal_closed, 2) do
            apply(__MODULE__, :handle_modal_closed, [socket, name])
          else
            socket
          end

        {:ok, socket}
      end

      def reset_fabric(%Phoenix.LiveView.Socket{} = socket) do
        reset_children(socket)
      end

      def compose_element(%Phoenix.LiveView.Socket{assigns: assigns} = socket, element_id)
          when is_atom(element_id) or is_binary(element_id) do
        %Phoenix.LiveView.Socket{socket | assigns: compose_element(assigns, element_id)}
      end

      def compose_element(%{} = assigns, element_id)
          when is_atom(element_id) or is_binary(element_id) do
        element = compose(element_id, assigns)
        Phoenix.Component.assign(assigns, element_id, element)
      end

      def update_child(context, child_name) when is_atom(child_name) or is_binary(child_name) do
        if exists?(context, child_name) do
          compose_child(context, child_name)
        else
          context
        end
      end

      def add_child(
            %Phoenix.LiveView.Socket{assigns: assigns} = socket,
            child_name,
            %{} = child_map
          ) do
        %Phoenix.LiveView.Socket{
          socket
          | assigns: Fabric.compose_child(assigns, child_name, child_map)
        }
      end

      def compose_child(%Phoenix.LiveView.Socket{assigns: assigns} = socket, child_name) do
        %Phoenix.LiveView.Socket{socket | assigns: compose_child(assigns, child_name)}
      end

      def compose_child(%{fabric: _} = assigns, child_name)
          when is_atom(child_name) or is_binary(child_name) do
        Fabric.compose_child(assigns, child_name, compose(child_name, assigns))
      end

      def compose(id, assigns) do
        Logger.error("compose/2 not implemented")
        nil
      end

      defoverridable compose: 2

      def async(%Phoenix.LiveView.Socket{assigns: assigns} = socket, name, closure) do
        async(assigns, name, closure)
      end

      def async(%{fabric: fabric}, name, closure) do
        async(fabric, name, closure)
      end

      def async(%Fabric.Model{self: self}, name, closure) when is_function(closure, 0) do
        Task.async(fn ->
          %{async: %{source: self, event: name, result: closure.()}}
        end)
      end
    end
  end

  def compose_child(%{fabric: fabric} = assigns, child_name, %{} = child_map) do
    child = prepare_child(fabric, child_name, child_map)
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  def compose_child(%{fabric: fabric} = assigns, child_name, nil) do
    Phoenix.Component.assign(assigns, fabric: remove_child(fabric, child_name))
  end

  # Child id

  def child_id(%Fabric.Model{self: self}, child_name), do: child_id(self, child_name)

  def child_id(%{pid: _pid}, child_name) do
    child_id("page", child_name)
  end

  def child_id(%{id: id}, child_name), do: child_id(id, child_name)

  def child_id(context, child_name) when is_atom(child_name),
    do: child_id(context, child_name |> Atom.to_string())

  def child_id(context, child_name) when is_binary(child_name) do
    [child_name, context]
    |> Enum.join(@html_id_seperator)
    |> String.replace(@html_id_invalid, @html_id_replacement)
  end

  # Prepare

  def prepare_child(context, child_name, %{module: module, params: params}) do
    prepare_child(context, child_name, module, params)
  end

  def prepare_child(
        %Phoenix.LiveView.Socket{assigns: assigns},
        child_name,
        module,
        params
      ) do
    prepare_child(assigns, child_name, module, params)
  end

  def prepare_child(%{fabric: fabric}, child_name, module, params) do
    prepare_child(fabric, child_name, module, params)
  end

  def prepare_child(%Fabric.Model{self: self}, child_name, module, params) do
    child_id = child_id(self, child_name)
    child_ref = %Fabric.LiveComponent.RefModel{id: child_id, name: child_name, module: module}
    child_fabric = %Fabric.Model{parent: self, self: child_ref, children: nil}
    params = Map.put(params, :fabric, child_fabric)

    %Fabric.LiveComponent.Model{ref: child_ref, params: params}
  end

  # Install

  def install_children(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket, children)
      when is_list(children) do
    Phoenix.Component.assign(socket, fabric: install_children(fabric, children))
  end

  def install_children(%{fabric: fabric} = assigns, children) when is_list(children) do
    Phoenix.Component.assign(assigns, fabric: install_children(fabric, children))
  end

  def install_children(%Fabric.Model{} = fabric, children) when is_list(children) do
    %Fabric.Model{fabric | children: children}
  end

  # Reset
  def reset_children(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket) do
    Phoenix.Component.assign(socket, fabric: reset_children(fabric))
  end

  def reset_children(%Fabric.Model{} = fabric) do
    %Fabric.Model{fabric | children: []}
  end

  # CRUD

  def get_child(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}}, child_name) do
    get_child(fabric, child_name)
  end

  def get_child(%{fabric: fabric}, child_name) do
    get_child(fabric, child_name)
  end

  def get_child(%Fabric.Model{children: children}, child_name) do
    Enum.find(List.wrap(children), &(&1.ref.name == child_name))
  end

  def exists?(context, child_name) do
    get_child(context, child_name) != nil
  end

  def new_fabric(%Phoenix.LiveView.Socket{} = socket) do
    fabric = new_fabric()
    Phoenix.Component.assign(socket, :fabric, fabric)
  end

  def new_fabric() do
    %Fabric.Model{parent: nil, children: nil}
  end

  def show_child(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: show_child(assigns, child)}
  end

  def show_child(%{fabric: fabric} = assigns, %Fabric.LiveComponent.Model{} = child) do
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  def replace_child(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: replace_child(assigns, child)}
  end

  def replace_child(
        %{fabric: fabric} = assigns,
        %Fabric.LiveComponent.Model{ref: %{id: id}} = child
      ) do
    Phoenix.Component.assign(assigns,
      fabric:
        fabric
        |> remove_child(id)
        |> add_child(child)
    )
  end

  def hide_child(%Phoenix.LiveView.Socket{assigns: assigns} = socket, child_name) do
    %Phoenix.LiveView.Socket{socket | assigns: hide_child(assigns, child_name)}
  end

  def hide_child(%{fabric: fabric} = assigns, child_name) do
    Phoenix.Component.assign(assigns, fabric: remove_child(fabric, child_name))
  end

  # MODAL

  def prepared_modal?(context, child_name) do
    if child = get_child(context, child_name) do
      Map.get(child, :prepared_modal_style) != nil
    else
      false
    end
  end

  def prepare_modal(context, nil, _modal_style) do
    Logger.error("Can not prepare modal with unknown child")
    context
  end

  def prepare_modal(context, child_name, modal_style)
      when is_atom(child_name) or is_binary(child_name) do
    child = get_child(context, child_name)
    prepared_modal_style = Map.get(child, :prepared_modal_style)

    if prepared_modal_style do
      Logger.debug("already prepared modal style #{prepared_modal_style} for #{child_name}")
      context
    else
      child |> Map.put(child, prepared_modal_style: modal_style)
      prepare_modal(context, child, modal_style)
    end
  end

  def prepare_modal(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child,
        modal_style
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: prepare_modal(assigns, child, modal_style)}
  end

  def prepare_modal(
        %{fabric: fabric} = assigns,
        %Fabric.LiveComponent.Model{} = child,
        modal_style
      ) do
    send_event(fabric, :root, "prepare_modal", %{live_component: child, style: modal_style})
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  def show_modal(context, child_name, modal_style)
      when is_atom(child_name) or is_binary(child_name) do
    child = get_child(context, child_name)
    show_modal(context, child, modal_style)
  end

  def show_modal(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child,
        modal_style
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: show_modal(assigns, child, modal_style)}
  end

  def show_modal(%{fabric: fabric} = assigns, %Fabric.LiveComponent.Model{} = child, modal_style) do
    send_event(fabric, :root, "show_modal", %{live_component: child, style: modal_style})
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  def hide_modal(%Phoenix.LiveView.Socket{assigns: assigns} = socket, child_name) do
    %Phoenix.LiveView.Socket{socket | assigns: hide_modal(assigns, child_name)}
  end

  def hide_modal(%{fabric: fabric} = assigns, child_name) do
    if child = get_child(fabric, child_name) do
      send_event(fabric, :root, "hide_modal", %{live_component: child})
      Phoenix.Component.assign(assigns, fabric: remove_child(fabric, child_name))
    else
      Logger.warning("Can not hide modal with unknown child '#{child_name}'")
      assigns
    end
  end

  @doc """
    Sends a handle_modal_closed event to the live component. This event is handled by Fabric and is
    delegated as an optional callback to the parent. See Fabric.__using__/1 for more information.
  """
  def handle_modal_closed(
        %Phoenix.LiveView.Socket{} = socket,
        %Fabric.LiveComponent.RefModel{} = ref
      ) do
    send_event(ref, %{name: :handle_modal_closed, payload: %{live_component: %{ref: ref}}})
    socket
  end

  # POPUP

  # deprecated "Use show_modal/3 instead"
  def show_popup(context, child_name) when is_atom(child_name) or is_binary(child_name) do
    if child = get_child(context, child_name) do
      show_popup(context, child)
    else
      raise "Unable to show popup with unknown child '#{child_name}'"
    end
  end

  # deprecated "Use show_modal/3 instead"
  def show_popup(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: show_popup(assigns, child)}
  end

  # deprecated "Use show_modal/3 instead"
  def show_popup(%{fabric: fabric} = assigns, %Fabric.LiveComponent.Model{} = child) do
    send_event(fabric, :root, "show_popup", child)
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  # deprecated "Use hide_modal/2 instead"
  def hide_popup(%Phoenix.LiveView.Socket{assigns: assigns} = socket, child_name) do
    %Phoenix.LiveView.Socket{socket | assigns: hide_popup(assigns, child_name)}
  end

  # deprecated "Use hide_modal/2 instead"
  def hide_popup(%{fabric: fabric} = assigns, child_name) do
    send_event(fabric, :root, "hide_popup")
    Phoenix.Component.assign(assigns, fabric: remove_child(fabric, child_name))
  end

  # Flow
  def show_next(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket, current) do
    Phoenix.Component.assign(socket, fabric: show_next(fabric, current))
  end

  def show_next(%Fabric.Model{children: nil} = fabric, _current_ref) do
    # Possible race condition with live updates from server
    Logger.warning("Can not show next child, no childs in flow")
    fabric
  end

  def show_next(%Fabric.Model{children: []} = fabric, _current_ref) do
    # Possible race condition with live updates from server
    Logger.warning("Can not show next child, no childs in flow")
    fabric
  end

  def show_next(%Fabric.Model{children: [_child]} = fabric, _current_ref) do
    # Possible race condition with live updates from server
    Logger.warning("Can not show next child, only one child in flow")
    fabric
  end

  def show_next(%Fabric.Model{children: [head | tail]} = fabric, current_ref) do
    if head.ref == current_ref do
      %Fabric.Model{fabric | children: tail}
    else
      # Possible race condition with live updates from server
      Logger.warning("Can not show next child, current child is not the first child in flow")
      fabric
    end
  end

  def get_current_child(%Fabric.Model{children: children}) do
    List.wrap(children) |> List.first()
  end

  # BASICS

  def add_child(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket, child) do
    Phoenix.Component.assign(socket, fabric: add_child(fabric, child))
  end

  def add_child(%Fabric.Model{children: nil} = fabric, %Fabric.LiveComponent.Model{} = child) do
    %Fabric.Model{fabric | children: [child]}
  end

  def add_child(%Fabric.Model{children: children} = fabric, %Fabric.LiveComponent.Model{} = child) do
    children =
      if index = Enum.find_index(children, &(&1.ref.id == child.ref.id)) do
        List.replace_at(children, index, child)
      else
        List.wrap(children) ++ List.wrap(child)
      end

    %Fabric.Model{fabric | children: children}
  end

  def remove_child(%Fabric.Model{} = fabric, nil), do: fabric

  def remove_child(%Fabric.Model{children: children} = fabric, child_name) do
    %Fabric.Model{
      fabric
      | children: Enum.filter(List.wrap(children), &(&1.ref.name != child_name))
    }
  end

  # Events

  def send_event(_, _, _, payload \\ %{})

  def send_event(
        %Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket,
        target,
        name,
        payload
      ) do
    send_event(fabric, target, name, payload)
    socket
  end

  def send_event(%Fabric.Model{}, :root, name, payload) do
    send_event(self(), %{name: name, payload: payload})
  end

  def send_event(%Fabric.Model{parent: nil}, :parent, name, _payload) do
    raise "Sending event '#{name}' to non-existing parent"
  end

  def send_event(%Fabric.Model{parent: parent, self: self}, :parent, name, payload) do
    payload = Map.put(payload, :source, self)
    send_event(parent, %{name: name, payload: payload})
  end

  def send_event(%Fabric.Model{self: self}, :self, name, payload) do
    send_event(self, %{name: name, payload: payload})
  end

  def send_event(%Fabric.Model{children: [%{ref: ref} | _]}, :flow, name, payload) do
    send_event(ref, %{name: name, payload: payload})
  end

  def send_event(%Fabric.Model{}, :flow, name, _payload) do
    raise "Sending event '#{name}' to empty flow"
  end

  def send_event(%Fabric.Model{} = fabric, child_name, name, payload) do
    if child = get_child(fabric, child_name) do
      send_event(child.ref, %{name: name, payload: payload})
    end
  end

  def send_event(%Fabric.LiveComponent.RefModel{id: id, module: module}, event) do
    Phoenix.LiveView.send_update(module, %{id: id, fabric_event: event})
  end

  def send_event(%Fabric.LiveView.RefModel{pid: pid}, event) do
    send_event(pid, event)
  end

  def send_event(pid, event) when is_pid(pid) do
    send(pid, %{fabric_event: event})
  end
end
