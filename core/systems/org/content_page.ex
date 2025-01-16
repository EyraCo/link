defmodule Systems.Org.ContentPage do
  use Systems.Content.Composer, :management_page

  alias Systems.Org

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Org.Public.get_node!(id, Org.NodeModel.preload_graph(:full))
  end

  @impl true
  def mount(%{"id" => id} = params, _, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "org_content/#{id}"

    {
      :ok,
      socket
      |> assign(
        tabbar_id: tabbar_id,
        initial_tab: initial_tab
      )
    }
  end

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
