defmodule CoreWeb.Live.Hook.Base do
  use Frameworks.Concept.LiveHook

  @impl true
  def on_mount(live_view_module, _params, _session, socket) do
    {
      :cont,
      socket
      |> assign(
        live_view_module: live_view_module,
        popup: nil,
        dialog: nil,
        modals: []
      )
    }
  end
end
