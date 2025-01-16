defmodule Systems.Project.NodePage do
  use Systems.Content.Composer, :live_workspace

  import Frameworks.Pixel.Empty
  import Frameworks.Pixel.Line
  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Breadcrumbs
  alias Systems.Project

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Project.Public.get_node!(String.to_integer(id), Project.NodeModel.preload_graph(:down))
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # Childs

  @impl true
  def compose(:project_item_form, %{focussed_item: item}) do
    %{
      module: Project.ItemForm,
      params: %{item: item}
    }
  end

  @impl true
  def compose(:create_item_view, %{vm: %{node: node}}) do
    %{
      module: Project.CreateItemView,
      params: %{node: node}
    }
  end

  # Events

  @impl true
  def handle_event("rename", %{"item" => item_id}, socket) do
    item = Project.Public.get_item!(String.to_integer(item_id))

    {
      :noreply,
      socket
      |> assign(focussed_item: item)
      |> compose_child(:project_item_form)
      |> show_modal(:project_item_form, :dialog)
    }
  end

  @impl true
  def handle_event("delete", %{"item" => item_id}, socket) do
    Project.Public.delete_item(String.to_integer(item_id))

    {
      :noreply,
      socket
      |> update_view_model()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("create_item", _params, socket) do
    {
      :noreply,
      socket
      |> compose_child(:create_item_view)
      |> show_modal(:create_item_view, :dialog)
    }
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{vm: %{item_cards: item_cards, node_cards: node_cards}}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(item_cards ++ node_cards, &(&1.id == card_id))
    {:noreply, push_navigate(socket, to: path)}
  end

  @impl true
  def handle_event("saved", %{source: %{name: modal_view}}, socket) do
    {:noreply, socket |> hide_modal(modal_view)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_workspace title={@vm.title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
        <:top_bar>
          <div class="hidden md:block">
            <Area.content>
              <div class="flex flex-row items-center h-navbar-height">
                <.live_component id="path" module={Breadcrumbs} elements={@vm.breadcrumbs}/>
              </div>
            </Area.content>
            <.line />
          </div>
        </:top_bar>
        <Area.content>
          <Margin.y id={:page_top} />
          <%= if Enum.count(@vm.node_cards) > 0 do %>
            <div class="flex flex-row items-center justify-center">
              <div class="h-full">
                <Text.title2 margin="">
                  <%= dgettext("eyra-project", "node.nodes.title") %>
                  <span class="text-primary"> <%= Enum.count(@vm.node_cards) %></span>
                </Text.title2>
              </div>
              <div class="flex-grow">
              </div>
              <div class="h-full pt-2px lg:pt-1">
                <Button.Action.send event="create_item">
                  <div class="sm:hidden">
                    <Button.Face.plain_icon label={dgettext("eyra-project", "create.item.button.short")} icon={:forward} />
                  </div>
                  <div class="hidden sm:block">
                    <Button.Face.plain_icon label={dgettext("eyra-project", "create.item.button")} icon={:forward} />
                  </div>
                </Button.Action.send>
              </div>
            </div>
            <Margin.y id={:title2_bottom} />
            <Grid.dynamic>
              <%= for card <- @vm.node_cards do %>
                <Project.CardView.dynamic card={card}/>
              <% end %>
            </Grid.dynamic>
            <.spacing value="L" />
          <% end %>

          <%= if Enum.count(@vm.item_cards) > 0 do %>
          <div class="flex flex-row items-center justify-center">
              <div class="h-full">
                <Text.title2 margin="">
                  <%= dgettext("eyra-project", "node.items.title") %>
                  <span class="text-primary"> <%= Enum.count(@vm.item_cards) %></span>
                </Text.title2>
              </div>
              <div class="flex-grow">
              </div>
              <div class="h-full pt-2px lg:pt-1">
                <Button.Action.send event="create_item">
                  <div class="sm:hidden">
                    <Button.Face.plain_icon label={dgettext("eyra-project", "add.new.item.button.short")} icon={:forward} />
                  </div>
                  <div class="hidden sm:block">
                    <Button.Face.plain_icon label={dgettext("eyra-project", "add.new.item.button")} icon={:forward} />
                  </div>
                </Button.Action.send>
              </div>
            </div>
            <Margin.y id={:title2_bottom} />
            <Grid.dynamic>
              <%= for card <- @vm.item_cards do %>
                <Project.CardView.dynamic card={card} />
              <% end %>
            </Grid.dynamic>
            <.spacing value="L" />
          <% else %>
            <div>
              <.empty
                title={dgettext("eyra-project", "node.empty.title")}
                body={dgettext("eyra-project", "node.empty.description")}
                illustration="cards"
                button={%{
                  action: %{type: :send, event: "create_item"},
                  face: %{type: :primary, label: dgettext("eyra-project", "add.first.item.button")}
                }}
              />
            </div>
          <% end %>
        </Area.content>
      </.live_workspace>
    </div>
    """
  end
end
