defmodule Systems.Admin.ConfigPage do
  use Systems.Content.Composer, :tabbar_page

  @impl true
  def get_model(_params, _session, _socket) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    {:ok, socket |> assign(initial_tab: initial_tab)}
  end

  @impl true
  def handle_event("change", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.tabbar_page
      title={@vm.title}
      tabs={@vm.tabs}
      tabbar_id={@vm.tabbar_id}
      show_errors={@vm.show_errors}
      initial_tab={@initial_tab}
      menus={@menus}
      modals={@modals}
      popup={@popup}
      dialog={@dialog}
    />
    """
  end
end
