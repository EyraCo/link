defmodule Systems.Pool.ParticipantPage do
  use Systems.Content.Composer, :live_workspace

  import CoreWeb.UI.Member
  import Frameworks.Pixel.Content

  alias Frameworks.Pixel.Text
  alias Systems.Budget
  alias Systems.Account

  @impl true
  def get_model(%{"id" => user_id}, _session, _socket) do
    Account.Public.get_user!(user_id, [:features, :profile])
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={dgettext("link-studentpool", "participant.title")} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @vm.member do %>
          <.member {@vm.member} />
        <% end %>
        <Margin.y id={:page_top} />

        <%= if Enum.count(@vm.wallets) > 0 do %>
          <div>
            <Text.title2>
              <%= dgettext("link-dashboard", "book.accounts.title") %>
            </Text.title2>
            <Budget.WalletView.list items={@vm.wallets} />
            <.spacing value="XL" />
          </div>
        <% end %>

        <%= if Enum.count(@vm.contributions) > 0 do %>
          <div>
            <Text.title2>
              <%= dgettext("eyra-advert", "advert.subject.title") %>
              <span class="text-primary"> <%= Enum.count(@vm.contributions) %></span>
            </Text.title2>
            <.list items={@vm.contributions} />
            <.spacing value="XL" />
          </div>
        <% end %>

      </Area.content>
    </.live_workspace>
    """
  end
end
