defmodule Systems.Support.TicketPage do
  use Systems.Content.Composer, :live_workspace

  import CoreWeb.UI.Member
  import Frameworks.Pixel.Content

  alias Frameworks.Pixel.Text
  alias Systems.Support

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Support.Public.get_ticket!(id)
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
    }
  end

  @impl true
  def handle_event("close_ticket", _params, %{assigns: %{id: id}} = socket) do
    Support.Public.close_ticket_by_id(id)
    {:noreply, push_navigate(socket, to: ~p"/support/ticket")}
  end

  @impl true
  def handle_event("reopen_ticket", _params, %{assigns: %{id: id}} = socket) do
    Support.Public.reopen_ticket_by_id(id)
    {:noreply, push_navigate(socket, to: ~p"/support/ticket")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={dgettext("eyra-admin", "ticket.title")} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @vm.member do %>
          <.member {@vm.member} />
        <% end %>
        <Margin.y id={:page_top} />
        <div class="flex flex-row gap-4 items-center">
          <.wrap>
            <.tag {@vm.tag} />
          </.wrap>
          <div class="text-label font-label text-grey1">
            #<%= @vm.id %>
          </div>
          <div class="text-label font-label text-grey2">
            <%= @vm.timestamp %>
          </div>
        </div>
        <.spacing value="S" />
        <Text.title2><%= @vm.title %></Text.title2>
        <div class="text-bodymedium sm:text-bodylarge font-body mb-6 md:mb-8 lg:mb-10"><%=@vm.description %></div>
        <.wrap>
          <Button.dynamic {@vm.button} />
        </.wrap>
      </Area.content>
    </.live_workspace>
    """
  end
end
