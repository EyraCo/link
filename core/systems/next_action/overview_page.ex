defmodule Systems.NextAction.OverviewPage do
  @moduledoc """
   The todo screen.
  """
  use Systems.Content.Composer, :live_workspace

  alias Systems.NextAction

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> refresh_next_actions()
    }
  end

  def handle_view_model_updated(socket) do
    refresh_next_actions(socket)
  end

  def refresh_next_actions(%{assigns: %{current_user: user}} = socket) do
    assign(
      socket,
      :next_actions,
      NextAction.Public.list_next_actions(user)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={dgettext("eyra-ui", "todo.title")} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <%= if Enum.empty?(@vm.next_actions) do %>
        <div class="h-full">
          <div class="flex flex-col items-center w-full h-full">
            <div class="flex-grow" />
            <div class="flex-none">
              <img src={~p"/images/illustrations/zero-todo.svg"} id="zero-todos" alt="All done">
            </div>
            <div class="flex-grow" />
          </div>
        </div>
      <% else %>
        <Area.content>
          <Margin.y id={:page_top} />
          <div class="flex flex-col gap-6 sm:gap-10" id="next-actions">
            <%= for action <- @vm.next_actions do %>
              <NextAction.View.normal {action} />
            <% end %>
          </div>
        </Area.content>
      <% end %>
    </.live_workspace>
    """
  end
end
