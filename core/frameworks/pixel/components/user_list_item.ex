defmodule Frameworks.Pixel.UserListItem do
  @moduledoc """
    User list item
  """
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  @impl true
  def update(%{people_item: people_item} = assigns, socket),
    do: update_assigns_for_item(assigns, people_item, socket)

  @impl true
  def update(%{user_item: user_item} = assigns, socket),
    do: update_assigns_for_item(assigns, user_item, socket)

  defp update_assigns_for_item(_, item, socket) do
    socket =
      socket
      |> assign_new(:info, fn -> nil end)
      |> assign(:confirm_row_visible?, item[:confirm_row_visible?] || false)
      |> assign(:confirm_row_text, item[:confirm_row_text])
      |> assign(:confirm_row_action_buttons, item[:confirm_row_action_buttons])
      |> assign(:name, item.name)
      |> assign(:email, item.email)
      |> assign(:action_buttons, item.action_buttons)
      |> assign(:photo_url, item.photo_url)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <tr class="h-12">
        <td class="w-[44px]">
          <img
            src={@photo_url}
            class="rounded-full w-8 h-8 border-2 border-grey4"
            alt=""
          />
        </td>
        <td>
          <Text.label><%= @name %></Text.label>
        </td>
        <td>
          <Text.body_small><%= @email %></Text.body_small>
        </td>
        <%= if @info do %>
          <td>
            <Text.body_small color="text-grey2"><%= @info %></Text.body_small>
          </td>
        <% end %>
        <%= if @action_buttons do %>
          <td>
            <div class="flex flex-row">
              <div class="flex-grow" />
              <Button.dynamic_bar buttons={@action_buttons} />
            </div>
          </td>
        <% end %>
      </tr>

      <%= if @confirm_row_visible? do %>
        <tr class="h-12 text-white bg-primary">
          <%= if @confirm_row_text do %>
            <td colspan="3" class="px-2">
              <Text.body_small color="text-white"><%= @confirm_row_text %></Text.body_small>
            </td>
          <% end %>
          <%= if @confirm_row_action_buttons do %>
            <td class="px-2">
              <div class="flex flex-grow justify-end">
                <div class="flex-grow" />
                <Button.dynamic_bar buttons={@confirm_row_action_buttons}/>
              </div>
            </td>
          <% end %>
        </tr>
      <% end %>
    </div>
    """
  end
end
