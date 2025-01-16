defmodule Systems.Graphite.LeaderboardContentPage do
  use Systems.Content.Composer, :management_page

  alias Systems.Graphite

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Graphite.Public.get_leaderboard!(id)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Graphite.Public.get_leaderboard!(
      String.to_integer(id),
      Graphite.LeaderboardModel.preload_graph(:down)
    )
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "leaderboard_content/#{id}"

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
