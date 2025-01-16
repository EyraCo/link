defmodule Systems.Feldspar.ContentPage do
  use Systems.Content.Composer, :management_page

  alias Systems.Feldspar

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Feldspar.Public.get_tool!(id)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Feldspar.Public.get_tool!(String.to_integer(id), Feldspar.ToolModel.preload_graph(:down))
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "feldspar_content/#{id}"

    {
      :ok,
      socket
      |> assign(initial_tab: initial_tab, tabbar_id: tabbar_id)
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
