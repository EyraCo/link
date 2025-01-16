defmodule Systems.Advert.ContentPage do
  @moduledoc """
  The CMS page for Advert tool
  """
  use Systems.Content.Composer, :management_page

  alias Systems.Advert

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Advert.Public.get!(String.to_integer(id), Advert.Model.preload_graph(:down))
  end

  @impl true
  def mount(%{"id" => id} = params, _, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "advert_content/#{id}"

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
