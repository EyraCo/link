defmodule CoreWeb.Menu.Helpers do
  use CoreWeb.Menu.Items

  require CoreWeb.Gettext

  alias EyraUI.Navigation.MenuItem
  alias CoreWeb.Router.Helpers, as: Routes

  defp size(%{size: size}), do: size
  defp size(_), do: :default

  def live_item(socket, id, active_item, use_icon \\ true) when is_atom(id) do
    info = info(id)
    size = size(info)

    title =
      if size == :large do
        nil
      else
        title(id)
      end

    icon =
      if use_icon do
        %{
          name: id,
          size: size
        }
      else
        nil
      end

    path = Routes.live_path(socket, info.target)
    action = %{path: path}

    %MenuItem.ViewModel{
      id: id,
      title: title,
      icon: icon,
      action: action,
      active: active_item === id
    }
  end

  def account_item(socket, is_logged_in, active_item, use_icon \\ true) do
    if is_logged_in do
      live_item(socket, :profile, active_item, use_icon)
    else
      user_session_item(socket, :signin, use_icon)
    end
  end

  def alpine_item(id, active_item, use_icon, overlay) do
    info = info(id)
    size = size(info)

    title =
      if size == :large do
        nil
      else
        title(id)
      end

    icon =
      if use_icon do
        %{
          name: id,
          size: size
        }
      else
        nil
      end

    method = :alpine
    action = %{click_handler: info.target, method: method, overlay: overlay}

    %MenuItem.ViewModel{
      id: id,
      title: title,
      icon: icon,
      action: action,
      active: active_item === id
    }
  end

  def user_session_item(socket, id, use_icon) do
    info = info(id)
    size = size(info)

    title =
      if size == :large do
        nil
      else
        title(id)
      end

    icon =
      if use_icon do
        %{name: id, size: size}
      else
        nil
      end

    method =
      if info.target === :delete do
        :delete
      else
        :get
      end

    action = %{path: Routes.user_session_path(socket, method), method: method}
    %MenuItem.ViewModel{id: id, title: title, icon: icon, action: action}
  end

  def language_switch_item(socket, page_id) do
    [locale | _] = supported_languages()

    title = locale.name
    icon = %{name: locale.id, size: :default}

    redir =
      if page_id do
        Routes.live_path(socket, socket.view, page_id)
      else
        Routes.live_path(socket, socket.view)
      end

    path = Routes.language_switch_path(socket, :index, locale.id, redir: redir)
    action = %{path: path, dead: true}
    %MenuItem.ViewModel{id: locale.id, title: title, icon: icon, action: action}
  end

  def supported_languages do
    current_locale = Gettext.get_locale(CoreWeb.Gettext)

    [
      %{id: "en", name: CoreWeb.Gettext.gettext("English")},
      %{id: "nl", name: CoreWeb.Gettext.gettext("Dutch")}
    ]
    |> Enum.reject(fn %{id: locale} -> current_locale == locale end)
  end
end
