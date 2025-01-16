defmodule Systems.Assignment.ContentPage do
  use Systems.Content.Composer, :management_page

  alias Systems.Assignment
  alias Systems.Crew

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Assignment.Public.get!(String.to_integer(id), Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "assignment_content/#{id}"

    {
      :ok,
      socket
      |> assign(initial_tab: initial_tab, tabbar_id: tabbar_id)
      |> ensure_tester_role()
    }
  end

  defp ensure_tester_role(%{assigns: %{current_user: user, model: %{crew: crew}}} = socket) do
    if Crew.Public.get_member(crew, user) == nil do
      Crew.Public.apply_member_with_role(crew, user, :tester)
    end

    socket
  end

  @impl true
  def handle_uri(socket) do
    update_view_model(socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.management_page
        title={@vm.title}
        tabs={@vm.tabs}
        show_errors={@vm.show_errors}
        breadcrumbs={@vm.breadcrumbs}
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
