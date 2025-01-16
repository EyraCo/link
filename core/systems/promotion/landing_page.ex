defmodule Systems.Promotion.LandingPage do
  @moduledoc """
  The public promotion screen.
  """
  use Systems.Content.Composer, :live_website

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Viewport, __MODULE__})

  import Systems.Promotion.BannerView

  alias Core.ImageHelpers
  alias Frameworks.Pixel.Hero
  alias Frameworks.Pixel.Card

  import CoreWeb.Devices
  import CoreWeb.Language

  alias Systems.Promotion

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Promotion.Public.get!(id, Promotion.Model.preload_graph(:down))
  end

  @impl true
  def mount(
        _params,
        _session,
        %{assigns: %{current_user: user, model: promotion}} = socket
      ) do
    if Phoenix.LiveView.connected?(socket) do
      Promotion.Private.log_performance_event(promotion, :views)
    end

    {
      :ok,
      socket
      |> assign(
        user: user,
        image_info: nil
      )
      |> update_image_info()
    }
  end

  def handle_view_model_updated(socket) do
    update_image_info(socket)
  end

  @impl true
  def handle_resize(socket) do
    update_image_info(socket)
  end

  defp update_image_info(
         %{assigns: %{viewport: %{"width" => viewport_width}, vm: %{image_id: image_id}}} = socket
       ) do
    assign(socket, image_info: ImageHelpers.get_image_info(image_id, viewport_width, 720))
  end

  defp update_image_info(%{assigns: %{vm: %{image_id: image_id}}} = socket) do
    assign(socket, image_info: ImageHelpers.get_image_info(image_id, 1376, 720))
  end

  @impl true
  def handle_event("call-to-action-1", params, socket) do
    handle_event("call-to-action", params, socket)
  end

  @impl true
  def handle_event("call-to-action-2", params, socket) do
    handle_event("call-to-action", params, socket)
  end

  @impl true
  def handle_event("call-to-action", _params, %{assigns: %{preview: true}} = socket) do
    title = dgettext("eyra-promotion", "preview.inform.title")
    text = dgettext("eyra-promotion", "preview.inform.text")

    {
      :noreply,
      socket
      |> inform(title, text)
    }
  end

  @impl true
  def handle_event(
        "call-to-action",
        _params,
        %{assigns: %{vm: %{call_to_action: %{handle: handle}}}} = socket
      ) do
    {:noreply, handle.(socket)}
  end

  @impl true
  def handle_event("call-to-action", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("inform_ok", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  defp grid_cols(1), do: "grid-cols-1 sm:grid-cols-1"
  defp grid_cols(2), do: "grid-cols-1 sm:grid-cols-2"
  defp grid_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  @impl true
  def render(assigns) do
    ~H"""
    <div id={:promotion_landing_page} phx-hook="Viewport">
    <.live_website user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <:hero>
        <div class="h-[360px] bg-grey5">
          <Hero.image_large title={@vm.title} subtitle={@vm.themes} image_info={@image_info}>
            <:call_to_action>
              <Button.primary_live_view label={@vm.call_to_action.label} event="call-to-action-1" />
            </:call_to_action>
          </Hero.image_large>
        </div>
        <Hero.banner icon_url={@vm.icon_url} />
      </:hero>

      <Area.content>
        <Margin.y id={:page_top} />
        <div class="ml-8 mr-8 text-center">
          <Text.title1><%= @vm.subtitle %></Text.title1>
        </div>

        <div class="mb-12 sm:mb-16" />
        <div class={"grid gap-6 sm:gap-8 #{grid_cols(Enum.count(@vm.highlights))}"}>
          <%= for highlight <- @vm.highlights do %>
            <Card.highlight {highlight} />
          <% end %>
        </div>
        <div class="mb-12 sm:mb-16" />

        <Text.title2 margin=""><%= dgettext("eyra-promotion", "expectations.public.label") %></Text.title2>
        <.spacing value="M" />
        <Text.body_large><%= @vm.expectations %></Text.body_large>
        <.spacing value="M" />
        <Text.title2 margin=""><%= dgettext("eyra-promotion", "description.public.label") %></Text.title2>
        <.spacing value="M" />
        <Text.body_large><%= @vm.description %></Text.body_large>
        <.spacing value="L" />

        <.advert_banner
          photo_url={@vm.banner_photo_url}
          placeholder_photo_url={CoreWeb.Endpoint.static_path("/images/profile_photo_default.svg")}
          title={@vm.banner_title}
          subtitle={@vm.banner_subtitle}
          url={@vm.banner_url}
          logo_url={@vm.logo_url}
        />
        <.spacing value="L" />
        <div class="flex flex-col justify-center sm:flex-row gap-4 sm:gap-8 items-center">
          <.devices label={dgettext("eyra-promotion", "devices.available.label")} devices={@vm.devices} />
          <.language
            label={dgettext("eyra-promotion", "language.available.label")}
            language={@vm.language}
          />
        </div>
        <.spacing value="XL" />

        <Button.primary_live_view label={@vm.call_to_action.label} event="call-to-action-2" />
      </Area.content>
    </.live_website>
    </div>
    """
  end
end
