defmodule Systems.Storage.EndpointContentPage do
  use Systems.Content.Composer, :management_page

  alias Systems.Storage

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Storage.Public.get_endpoint!(
      String.to_integer(id),
      Storage.EndpointModel.preload_graph(:down)
    )
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "storage_content/#{id}"

    {
      :ok,
      socket
      |> assign(initial_tab: initial_tab, tabbar_id: tabbar_id)
    }
  end

  def handle_view_model_updated(%{assigns: %{vm: vm}} = socket) do
    if tab = Enum.find(vm.tabs, &(&1.id == :data_view)) do
      Fabric.send_event(tab.child.ref, %{name: "update_files", payload: %{}})
    end

    socket
  end

  @impl true
  def handle_uri(socket), do: update_view_model(socket)

  @impl true
  def render(assigns) do
    ~H"""
      <.management_page
        title={@vm.title}
        breadcrumbs={@vm.breadcrumbs}
        tabs={@vm.tabs}
        show_errors={@vm.show_errors}
        actions={@actions}
        tabbar_id={@tabbar_id}
        initial_tab={@initial_tab}
        tabbar_size={@tabbar_size}
        menus={@menus}
        modals={@modals}
        popup={@popup}
        dialog={@dialog}
      />
    """
  end
end
