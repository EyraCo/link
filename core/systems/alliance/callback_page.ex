defmodule Systems.Alliance.CallbackPage do
  @moduledoc """
  The redirect page to complete a task
  """
  use Systems.Content.Composer, :live_workspace

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button
  alias Frameworks.Concept.Directable

  alias Systems.{
    Assignment,
    Alliance
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, %{assigns: %{current_user: user}}) do
    tool = Alliance.Public.get_tool!(id)
    Directable.director(tool).authorization_context(tool, user)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Alliance.Public.get_tool!(id)
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(active_menu_item: nil)
      |> activate_participant_task()
    }
  end

  defp activate_participant_task(
         %{assigns: %{vm: %{state: :participant}, model: model, current_user: user}} = socket
       ) do
    Assignment.Public.complete_task(model, user)
    socket
  end

  defp activate_participant_task(socket), do: socket

  @impl true
  def handle_event(
        "call-to-action",
        _params,
        %{
          assigns: %{
            vm: %{call_to_action: %{handle: handle}}
          }
        } = socket
      ) do
    {:noreply, handle.(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.hero_title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title1><%= @vm.title %></Text.title1>
        <.spacing value="M" />
        <%= if @vm.state == :expired do %>
          <div>
            <Text.title3><%= dgettext("eyra-crew", "task.expired.subtitle") %></Text.title3>
            <.spacing value="M" />
            <Text.body_large><%= dgettext("eyra-crew", "task.expired.text") %></Text.body_large>
          </div>
        <% end %>

        <%= if @vm.state == :tester do %>
          <div>
            <Text.title3><%= dgettext("eyra-crew", "tester.completed.subtitle") %></Text.title3>
            <.spacing value="M" />
            <Text.body_large><%= dgettext("eyra-crew", "tester.completed.text") %></Text.body_large>
          </div>
        <% end %>

        <%= if @vm.state == :participant do %>
          <div>
            <Text.title3><%= dgettext("eyra-crew", "task.completed.title") %></Text.title3>
            <.spacing value="M" />
            <Text.body_large><%= dgettext("eyra-crew", "task.completed.message.part1") %></Text.body_large>
            <.spacing value="XS" />
            <Text.body_large><%= dgettext("eyra-crew", "task.completed.message.part2") %></Text.body_large>
          </div>
        <% end %>

        <.spacing value="L" />
        <Button.primary_live_view label={@vm.call_to_action.label} event="call-to-action" />
      </Area.content>
    </.live_workspace>
    """
  end
end
