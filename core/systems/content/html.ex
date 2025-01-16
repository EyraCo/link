defmodule Systems.Content.Html do
  use CoreWeb, :html

  import CoreWeb.Layouts.Workspace.Html, only: [workspace: 1]
  import CoreWeb.Layouts.Website.Html, only: [website: 1]
  import CoreWeb.Layouts.Stripped.Html, only: [stripped: 1]

  import CoreWeb.UI.Popup
  alias Frameworks.Pixel.ModalView
  import CoreWeb.UI.PlainDialog

  alias Frameworks.Pixel.Tabbed
  alias Frameworks.Pixel.Navigation

  attr(:modals, :map, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)

  def live_block(assigns) do
    ~H"""
    <div>
      <.popup_block popup={@popup} />
      <.plain_dialog_block dialog={@dialog} />
      <ModalView.dynamic modals={@modals} />
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)

  slot(:top_bar)
  slot(:inner_block, required: true)

  def live_workspace(assigns) do
    ~H"""
    <.workspace title={@title} menus={@menus} >
      <:top_bar>
        <%= render_slot(@top_bar) %>
      </:top_bar>

      <.live_block modals={@modals} popup={@popup} dialog={@dialog}/>

      <%= render_slot(@inner_block) %>
    </.workspace>
    """
  end

  attr(:user, :map, required: true)
  attr(:user_agent, :map, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)

  slot(:hero, required: true)
  slot(:inner_block, required: true)

  def live_website(assigns) do
    ~H"""
    <.website user={@user} user_agent={@user_agent} menus={@menus} >
      <:hero>
        <%= render_slot(@hero) %>
      </:hero>

      <.live_block modals={@modals} popup={@popup} dialog={@dialog}/>

      <%= render_slot(@inner_block) %>
    </.website>
    """
  end

  attr(:title, :string, default: nil)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)

  slot(:inner_block, required: true)

  def live_stripped(assigns) do
    ~H"""
    <.stripped title={@title} menus={@menus} >
      <.live_block modals={@modals} popup={@popup} dialog={@dialog}/>
      <%= render_slot(@inner_block) %>
    </.stripped>
    """
  end

  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)
  attr(:tabs, :list, required: true)
  attr(:tabbar_id, :atom, required: true)
  attr(:initial_tab, :string, required: true)
  attr(:show_errors, :string, required: true)

  def tabbar_page(assigns) do
    ~H"""
      <.live_workspace title={@title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
        <%= if Enum.count(@tabs) > 0 do %>
          <Navigation.tabbar>
            <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} type={:segmented} />
          </Navigation.tabbar>

          <div id="live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content tabs={@tabs} include_top_margin={false} />
          </div>
        <% end %>
      </.live_workspace>
    """
  end

  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)
  attr(:tabs, :list, required: true)
  attr(:tabbar_id, :atom, required: true)
  attr(:initial_tab, :string, required: true)
  attr(:tabbar_size, :atom, required: true)
  attr(:show_errors, :string, required: true)
  attr(:actions, :list, required: true)
  attr(:more_actions, :list, default: [])
  attr(:breadcrumbs, :list, required: true)

  def management_page(assigns) do
    ~H"""
      <div id={:content_management_page} phx-hook="Viewport">
        <.live_workspace title={@title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
          <:top_bar>
            <Navigation.action_bar breadcrumbs={@breadcrumbs} right_bar_buttons={@actions} more_buttons={@more_actions}>
              <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} size={@tabbar_size} />
            </Navigation.action_bar>
          </:top_bar>

          <div id="content_management_live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content tabs={@tabs} />
          </div>
          <Tabbed.footer tabs={@tabs} />
        </.live_workspace>
      </div>
    """
  end
end
