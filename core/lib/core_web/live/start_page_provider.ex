defmodule CoreWeb.StartPageProvider do
  @type page() :: map()
  @callback values() :: map()

  defp start_pages, do: Application.fetch_env!(:core, :start_pages)

  def pages(), do: start_pages().values()
  def page(%{researcher: true}), do: pages()[:researcher]
  def page(%{student: true}), do: pages()[:student]
  def page(%{coordinator: true}), do: pages()[:coordinator]
  def page(_), do: pages()[:member]

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Gettext

      def start_page_target(user) do
        case CoreWeb.StartPageProvider.page(user) do
          nil -> exit("Start page for #{user} not found in configuration")
          %{target: target} -> target
          _ -> exit("Start page for #{user} has no configuration for target")
        end
      end

      def start_page_title(user) do
        case CoreWeb.StartPageProvider.page(user) do
          nil ->
            exit("Start page not found in configuration for #{user}")

          %{id: id, domain: domain} ->
            Gettext.dgettext(CoreWeb.Gettext, domain, "start.page.#{id}")

          _ ->
            exit("Start page for #{user} has no configuration for domain")
        end
      end
    end
  end
end
