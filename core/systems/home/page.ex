defmodule Systems.Home.Page do
  use Systems.Content.Composer, :live_website

  alias Systems.Home
  alias Frameworks.Pixel.Hero

  @impl true
  def get_model(_params, _session, _socket) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> compose_child(:home_view)
    }
  end

  @impl true
  def compose(:home_view, %{vm: %{blocks: blocks}}) do
    %{
      module: Home.View,
      params: %{blocks: blocks}
    }
  end

  @impl true
  def handle_view_model_updated(socket) do
    # FIXME: consider to move updates of childs to Fabric.LiveHook
    socket |> update_child(:home_view)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_website user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <:hero>
        <Hero.dynamic {@vm.hero} />
      </:hero>
      <.child name={:home_view} fabric={@fabric} />
    </.live_website>
    """
  end
end
