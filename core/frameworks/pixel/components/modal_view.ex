defmodule Frameworks.Pixel.ModalView do
  use CoreWeb, :pixel

  require Logger
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  defmacro __using__(_) do
    quote do
      alias Frameworks.Pixel.ModalView

      @impl true
      def handle_event("prepare_modal", modal, socket) do
        Map.get(socket.assigns, :modals)

        {
          :noreply,
          socket |> upsert_modal(modal |> Map.put(:prepared, true))
        }
      end

      @impl true
      def handle_event("show_modal", modal, socket) do
        Map.get(socket.assigns, :modals)

        {
          :noreply,
          socket |> upsert_modal(modal |> Map.put(:prepared, false))
        }
      end

      @impl true
      def handle_event("hide_modal", modal, socket) do
        {:noreply, socket |> delete_modal(modal)}
      end

      @impl true
      def handle_event("hide_modals", _, socket) do
        {
          :noreply,
          socket |> assign(modals: [])
        }
      end

      @impl true
      def handle_event("close_modal", %{"item" => modal_id}, socket) do
        modal =
          socket
          |> modals()
          |> Enum.find(&(modal_id(&1) == modal_id))
          |> tap(
            &if &1 == nil do
              Logger.warning("Modal not found with ref: #{modal_id}")
            end
          )

        {
          :noreply,
          socket |> close_modal(modal)
        }
      end

      def close_modal(socket, %{live_component: %{ref: ref}} = modal) do
        socket
        |> delete_modal(modal)
        |> Fabric.handle_modal_closed(ref)
      end

      def upsert_modal(socket, modal) do
        if modal_exists?(socket, modal) do
          update_modal(socket, modal)
        else
          insert_modal(socket, modal)
        end
      end

      def show_modal(socket, modal) do
        if modal_exists?(socket, modal) do
          update_modal(socket, modal)
        else
          insert_modal(socket, modal)
        end
      end

      def update_modal(socket, modal) do
        socket
        |> delete_modal(modal)
        |> insert_modal(modal)
      end

      def insert_modal(%{assigns: %{modals: modals}} = socket, modal) do
        socket |> assign(modals: modals ++ [modal])
      end

      def delete_modal(%{assigns: %{modals: modals}} = socket, modal) do
        assign(socket, modals: Enum.reject(modals, &(modal_id(&1) == modal_id(modal))))
      end

      def modal_exists?(socket, modal) do
        socket
        |> modals()
        |> Enum.find(&(modal_id(&1) == modal_id(modal))) != nil
      end

      def modals(%{assigns: %{modals: modals}} = socket), do: modals
      def modals(_socket), do: []

      def modal_id(%{live_component: %{ref: %{id: id}}}), do: id
    end
  end

  attr(:modals, :map, default: [])

  def dynamic(assigns) do
    ~H"""
      <.background show={Enum.find(@modals, & &1.prepared == false) != nil} >
        <%= for modal <- @modals do %>
          <.panel {modal} />
        <% end %>
      </.background>
    """
  end

  attr(:show, :boolean, default: false)
  slot(:inner_block, required: true)

  def background(assigns) do
    ~H"""
    <div class={"modal-view fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-30 #{if @show do "block" else "hidden" end}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:style, :atom, required: true)
  attr(:live_component, :map, required: true)
  attr(:prepared, :boolean, default: false)
  attr(:index, :integer, required: true)

  def panel(%{style: style} = assigns) do
    allowed_styles = [:full, :page, :sheet, :dialog, :notification]

    unless style in allowed_styles do
      raise ArgumentError,
            "Invalid style: #{style}. Allowed styles are: #{Enum.join(allowed_styles, ", ")}"
    end

    ~H"""
      <div class={"w-full h-full #{if @prepared do "hidden" else "block" end}"} >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <.style_selector live_component={@live_component} style={@style} />
        </div>
      </div>
    """
  end

  attr(:live_component, :map, required: true)
  attr(:style, :atom, required: true)

  def style_selector(assigns) do
    ~H"""
      <%= if @style == :full do %>
        <.full live_component={@live_component} />
      <% end %>
      <%= if @style == :page do %>
        <.page live_component={@live_component} />
      <% end %>
      <%= if @style == :sheet do %>
        <.sheet live_component={@live_component} />
      <% end %>
      <%= if @style == :dialog do %>
        <.dialog live_component={@live_component} />
      <% end %>
      <%= if @style == :notification do %>
        <.notification live_component={@live_component} />
      <% end %>
    """
  end

  attr(:live_component, :string, required: true)

  def full(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center w-full h-full">
      <div class={"modal-full p-4 sm:p-12 lg:p-20 w-full h-full"}>
        <div class={"flex flex-col w-full bg-white rounded shadow-floating h-full pt-8 pb-8"}>
          <%!-- HEADER --%>
          <div class="shrink-0 px-8">
            <div class="flex flex-row">
              <div class="flex-grow"/>
              <.close_button live_component={@live_component} />
            </div>
          </div>
          <%!-- BODY --%>
          <div class="h-full overflow-y-scroll px-4">
            <.body live_component={@live_component} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:live_component, :string, required: true)

  def page(assigns) do
    ~H"""
      <div class={"modal-page w-[960px] p-4 sm:px-10 sm:py-20 h-full"}>
        <div class={"flex flex-col w-full bg-white rounded shadow-floating h-full pt-8 pb-8"}>
          <%!-- HEADER --%>
          <div class="shrink-0 px-8">
            <div class="flex flex-row">
              <div class="flex-grow">
                <.title live_component={@live_component} />
              </div>
              <.close_button live_component={@live_component} />
            </div>
          </div>
          <%!-- BODY --%>
          <div class="h-full overflow-y-scroll px-8">
            <.body live_component={@live_component} />
          </div>
        </div>
      </div>
    """
  end

  attr(:live_component, :string, required: true)

  def sheet(assigns) do
    ~H"""
      <div class={"modal-sheet w-[960px] p-4 sm:px-10 sm:py-20"}>
        <div class={"flex flex-col w-full bg-white rounded shadow-floating pt-8 pb-8"}>
          <%!-- HEADER --%>
          <div class="shrink-0 px-8">
            <div class="flex flex-row">
              <div class="flex-grow">
                <.title live_component={@live_component} centered?={true}/>
              </div>
              <.close_button live_component={@live_component} />
            </div>
          </div>
          <%!-- BODY --%>
          <div class="h-full overflow-y-scroll px-8">
            <.body live_component={@live_component} />
          </div>
        </div>
      </div>
    """
  end

  attr(:live_component, :string, required: true)

  def dialog(assigns) do
    ~H"""
      <div class="modal-dialog w-[700px] px-4 sm:px-10">
        <div class="relative h-full w-full bg-white pt-6 pb-9 px-9 rounded shadow-floating">
          <%!-- Floating close button --%>
          <div class="absolute z-30 top-6 right-9">
          <.close_button live_component={@live_component} />
          </div>
          <%!-- BODY --%>
          <div class="h-full w-full overflow-y-scroll">
            <.body live_component={@live_component} />
          </div>
        </div>
      </div>
    """
  end

  attr(:live_component, :string, required: true)

  def notification(assigns) do
    ~H"""
      <div class="modal-notification w-[700px] px-4 sm:px-10">
        <div class="relative h-full w-full bg-white pt-6 pb-9 px-9 rounded shadow-floating">
          <%!-- Floating close button --%>
          <div class="absolute z-30 top-9 right-9">
            <.close_button live_component={@live_component} />
          </div>
          <%!-- BODY --%>
          <div class="h-full w-full overflow-y-scroll">
            <.body live_component={@live_component} />
          </div>
        </div>
      </div>
    """
  end

  attr(:live_component, :map, required: true)
  attr(:centered?, :boolean, default: false)

  def title(assigns) do
    ~H"""
      <Text.title2 align={"#{if @centered? do "text-center" else "text-left" end}"}>
        <%= Map.get(@live_component.params, :title) %>
      </Text.title2>
    """
  end

  attr(:live_component, :map, required: true)

  def close_button(assigns) do
    ~H"""
      <Button.dynamic {
        %{
          action: %{type: :send, event: "close_modal", item: @live_component.ref.id},
          face: %{type: :icon, icon: :close}
        }
      } />
    """
  end

  attr(:live_component, :map, required: true)

  def body(assigns) do
    ~H"""
      <.live_component
        id={@live_component.ref.id}
        module={@live_component.ref.module}
        {@live_component.params}
      />
    """
  end
end
