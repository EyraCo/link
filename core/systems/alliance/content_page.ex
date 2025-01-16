defmodule Systems.Alliance.ContentPage do
  use Systems.Content.Composer, :management_page

  alias Systems.Alliance

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Alliance.Public.get_tool!(String.to_integer(id))
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "alliance_content/#{id}"

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
        tabs={@vm.tabs}
        show_errors={@vm.show_errors}
        breadcrumbs={@vm.breadcrumbs}
        menus={@menus}
        modals={@modals}
        popup={@popup}
        dialog={@dialog}
        tabbar_id={@tabbar_id}
        initial_tab={@initial_tab}
        tabbar_size={@tabbar_size}
        actions={@actions}
      />
    """
  end
end
