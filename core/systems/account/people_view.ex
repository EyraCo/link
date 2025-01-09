defmodule Systems.Account.PeopleView do
  use CoreWeb.LiveForm

  alias Core.ImageHelpers
  alias Frameworks.Pixel.{SearchBar, UserListItem}
  alias Systems.Account

  @impl true
  def update(%{users: users, people: people, title: title, current_user: current_user}, socket) do
    {:ok,
     socket
     |> assign_defaults(users, people, title, current_user)
     |> update_people_items()
     |> update_search_message()
     |> compose_child(:search_bar)}
  end

  @impl true
  def handle_event(
        "search_query",
        %{
          source: %Fabric.LiveComponent.RefModel{name: :search_bar},
          query_string: raw_query_string
        },
        socket
      ) do
    query_string = String.trim(raw_query_string)

    {:noreply,
     socket
     |> assign(:query_string, query_string)
     |> update_user()
     |> update_search_message()}
  end

  @impl true
  def handle_event(
        "add",
        %{"item" => user_id},
        %{assigns: %{users: users, people: people}} = socket
      ) do
    user_id = String.to_integer(user_id)

    {:noreply,
     case Enum.find(users, &(&1.id == user_id)) do
       nil ->
         flash_error(socket)

       user ->
         socket
         |> assign(users: Enum.reject(users, &(&1.id == user_id)), people: people ++ [user])
         |> reset_search_fields()
         |> update_people_items()
         |> update_search_message()
         |> send_event(:parent, "add_user", %{user: user})
     end}
  end

  @impl true
  def handle_event("remove", %{"item" => user_id}, socket) do
    {:noreply, remove_user(String.to_integer(user_id), socket)}
  end

  @impl true
  def handle_event(
        "cancel_remove",
        %{"item" => user_id},
        %{assigns: %{confirm_removal_user_ids: ids}} = socket
      ) do
    {:noreply,
     socket
     |> assign(:confirm_removal_user_ids, MapSet.delete(ids, String.to_integer(user_id)))
     |> update_people_items()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-10 h-full">
      <div class="py-3 px-6 border-2 border-grey4 rounded overflow-y-scroll">
        <table class="w-full">
          <%= for people_item <- @people_items do %>
            <.live_component module={UserListItem} id={people_item.email} people_item={people_item} />
          <% end %>
        </table>
      </div>

      <div>
        <Text.title5 align="text-left">
          <%= dgettext("eyra-account", "people.add.title") %>
        </Text.title5>
        <.spacing value="XS" />
        <.child name={:search_bar} fabric={@fabric} />

        <%= if @user_item do %>
          <.spacing value="S" />
          <div class="py-3 px-6 border-2 border-grey4 rounded">
            <table class="w-full">
              <.live_component module={UserListItem} id={@user_item.email} user_item={@user_item} />
            </table>
          </div>
        <% end %>

        <%= if @message do %>
          <.spacing value="S" />
          <div class="py-3 px-6 border-2 border-grey4 rounded">
            <div class="h-12 flex flex-col justify-center">
              <Text.body_medium><%= @message %></Text.body_medium>
            </div>
          </div>
        <% else %>
          <.spacing value="XS" />
        <% end %>
      </div>

      <div class="flex-grow" />
    </div>
    """
  end

  @impl true
  def compose(:search_bar, %{query_string: query_string}) do
    %{
      module: SearchBar,
      params: %{
        query_string: query_string,
        placeholder: dgettext("eyra-account", "people.search.placeholder"),
        debounce: "200"
      }
    }
  end

  # ------------------------------------------------------------------
  # Private Helpers
  # ------------------------------------------------------------------

  defp assign_defaults(socket, users, people, title, current_user) do
    query_string = Map.get(socket.assigns, :query_string, "")

    assign(socket,
      users: users,
      people: people,
      title: title,
      current_user: current_user,
      user_item: nil,
      query: Map.get(socket.assigns, :query, []),
      query_string: query_string,
      confirm_removal_user_ids: MapSet.new()
    )
  end

  defp update_search_message(%{assigns: %{query_string: "", message: _}} = socket),
    do: assign(socket, message: nil)

  defp update_search_message(
         %{assigns: %{user_item: nil, people: people, query_string: qs}} = socket
       )
       when qs not in [nil, ""] do
    message =
      if find_user_by_email(people, qs) do
        dgettext("eyra-account", "people.search.alread_added.message")
      else
        dgettext("eyra-account", "people.search.no_match.message")
      end

    assign(socket, message: message)
  end

  defp update_search_message(socket),
    do: assign(socket, message: nil)

  defp update_people_items(
         %{assigns: %{people: people, current_user: me, confirm_removal_user_ids: ids}} = socket
       ) do
    people_items =
      Enum.map(people, fn person ->
        build_user_display_data(:people, person, me, Enum.count(people), ids)
      end)

    assign(socket, people_items: people_items)
  end

  defp remove_user(
         user_id,
         %{assigns: %{people: people, current_user: me, confirm_removal_user_ids: ids}} = socket
       ) do
    case Enum.find(people, &(&1.id == user_id)) do
      nil ->
        flash_error(socket)

      user ->
        cond do
          user.id == me.id and not MapSet.member?(ids, user.id) ->
            socket
            |> assign(:confirm_removal_user_ids, MapSet.put(ids, user.id))
            |> update_people_items()
            |> update_search_message()

          user.id == me.id and MapSet.member?(ids, user.id) ->
            socket
            |> finalize_remove_user(user)
            |> send_event(:parent, "remove_user", %{user: user})

          true ->
            socket
            |> finalize_remove_user(user)
            |> send_event(:parent, "remove_user", %{user: user})
        end
    end
  end

  defp finalize_remove_user(socket, user) do
    %{users: users, people: people, confirm_removal_user_ids: ids} = socket.assigns
    new_people = Enum.reject(people, &(&1.id == user.id))
    new_users = users ++ [user]

    socket
    |> assign(:confirm_removal_user_ids, MapSet.delete(ids, user.id))
    |> assign(users: new_users, people: new_people)
    |> update_people_items()
    |> update_search_message()
  end

  defp reset_search_fields(socket),
    do: assign(socket, query_string: "", user_item: nil)

  defp find_user_by_email(users, email),
    do: Enum.find(users, &(&1.email == String.trim(email)))

  defp update_user(%{assigns: %{query_string: qs, users: users, current_user: me}} = socket) do
    user = find_user_by_email(users, qs)
    user_item = build_user_display_data(:search, user, me, 1)
    assign(socket, user: user, user_item: user_item)
  end

  defp build_user_display_data(_type, %Account.User{} = user, me, _count, ids) do
    photo_url = ImageHelpers.get_photo_url(user.profile)

    if user.id == me.id and MapSet.member?(ids, user.id) do
      %{
        photo_url: photo_url,
        name: user.displayname,
        email: user.email,
        action_buttons: [],
        confirm_row_visible?: true,
        confirm_row_text: dgettext("eyra-account", "people.confirm_remove.text"),
        confirm_row_action_buttons: [
          %{
            action: %{type: :send, event: "remove", item: user.id, target: me.id},
            face: %{
              type: :primary,
              label: dgettext("eyra-account", "people.confirm_remove.label")
            }
          },
          %{
            action: %{type: :send, event: "cancel_remove", item: user.id, target: me.id},
            face: %{type: :primary, label: dgettext("eyra-account", "people.cancel_remove.label")}
          }
        ]
      }
    else
      %{
        photo_url: photo_url,
        name: user.displayname,
        email: user.email,
        action_buttons: user_action_buttons(:people, user, me, 999)
      }
    end
  end

  defp build_user_display_data(_, nil, _, _, _), do: nil

  defp build_user_display_data(type, %Account.User{} = user, me, count) do
    photo_url = ImageHelpers.get_photo_url(user.profile)

    %{
      photo_url: photo_url,
      name: user.displayname,
      email: user.email,
      action_buttons: user_action_buttons(type, user, me, count)
    }
  end

  defp build_user_display_data(_, nil, _, _), do: nil

  defp user_action_buttons(:people, _, _, count) when count <= 1, do: []

  defp user_action_buttons(:people, %Account.User{} = user, %Account.User{} = me, _) do
    [
      %{
        action: %{type: :send, event: "remove", item: user.id, target: me.id},
        face: %{type: :icon, icon: :remove}
      }
    ]
  end

  defp user_action_buttons(:search, %Account.User{} = user, %Account.User{} = me, _) do
    [
      %{
        action: %{type: :send, event: "add", item: user.id, target: me.id},
        face: %{type: :plain, label: "Add", icon: :add}
      }
    ]
  end
end
