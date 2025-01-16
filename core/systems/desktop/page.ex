defmodule Systems.Desktop.Page do
  use Systems.Content.Composer, :live_workspace

  alias Systems.Desktop

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> compose_child(:desktop_view)
    }
  end

  @impl true
  def compose(:desktop_view, %{vm: vm}) do
    %{
      module: Desktop.View,
      params: %{vm: vm}
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <.child name={:desktop_view} fabric={@fabric}  />
    </.live_workspace>
    """
  end
end
