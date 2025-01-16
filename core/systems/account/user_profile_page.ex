defmodule Systems.Account.UserProfilePage do
  @moduledoc """
  The home screen.
  """
  use Systems.Content.Composer, :live_workspace

  alias Core

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> compose_child(:form)
    }
  end

  @impl true
  def handle_event(_, _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def compose(:form, %{vm: %{user: user}}) do
    %{
      module: Systems.Account.UserProfileForm,
      params: %{user: user}
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <.stack fabric={@fabric} />
    </.live_workspace>
    """
  end
end
