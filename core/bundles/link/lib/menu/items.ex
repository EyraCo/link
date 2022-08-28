defmodule Link.Menu.Items do
  @behaviour CoreWeb.Menu.ItemsProvider

  @impl true
  def values() do
    %{
      permissions: %{target: Systems.Admin.PermissionsPage, domain: "eyra-ui"},
      support: %{target: Systems.Support.OverviewPage, domain: "eyra-ui"},
      link: %{target: Link.Index, size: :large, title: "Panl", domain: "eyra-ui"},
      debug: %{target: Link.Debug, domain: "eyra-ui"},
      console: %{target: Link.Console, domain: "eyra-ui"},
      marketplace: %{target: Link.Marketplace, domain: "eyra-ui"},
      pools: %{target: Systems.Pool.OverviewPage, domain: "link-ui"},
      recruitment: %{target: Systems.Campaign.OverviewPage, domain: "link-ui"},
      todo: %{target: Systems.NextAction.OverviewPage, domain: "eyra-ui"},
      helpdesk: %{target: Systems.Support.HelpdeskPage, domain: "eyra-ui"},
      settings: %{target: CoreWeb.User.Settings, domain: "eyra-ui"},
      profile: %{target: CoreWeb.User.Profile, domain: "eyra-ui"},
      signout: %{target: :delete, domain: "eyra-ui"},
      signin: %{target: :new, domain: "eyra-ui"},
      menu: %{target: "mobile_menu = !mobile_menu", domain: "eyra-ui"}
    }
  end

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Gettext

      unquote do
        for {item_id, %{domain: domain}} <- Link.Menu.Items.values() do
          quote do
            dgettext(unquote(domain), unquote("menu.item.#{item_id}"))
          end
        end
      end
    end
  end
end
