defmodule Systems.Support.OverviewPage do
  use Systems.Content.Composer, :tabbar_page

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  @impl true
  def mount(params, _session, socket) do
    initial_tab = Map.get(params, "tab")

    {
      :ok,
      socket
      |> assign(tabbar_id: "support_overview", initial_tab: initial_tab)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.tabbar_page
        title={@vm.title}
        menus={@menus}
        modals={@modals}
        popup={@popup}
        dialog={@dialog}
        tabs={@vm.tabs}
        tabbar_id={@tabbar_id}
        initial_tab={@initial_tab}
        show_errors={@vm.show_errors}
      />
    """
  end
end
