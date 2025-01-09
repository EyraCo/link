defmodule Systems.Admin.AccountView do
  use CoreWeb, :live_component

  require Logger

  alias Core.ImageHelpers
  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.UserListItem

  alias Systems.Admin
  alias Systems.Account

  # Initial update
  @impl true
  def update(
        %{
          id: id,
          user: user,
          creators: creators
        },
        socket
      ) do
    form = to_form(%{"query" => nil})
    active_filters = Map.get(socket.assigns, :active_filters, [:creator])
    query = Map.get(socket.assigns, :query, [])
    query_string = Map.get(socket.assigns, :query_string, "")

    {
      :ok,
      socket
      |> assign(
        id: id,
        user: user,
        creators: creators,
        form: form,
        active_filters: active_filters,
        query: query,
        query_string: query_string,
        user_count: 0
      )
      |> update_users()
      |> compose_child(:filter_selector)
      |> compose_child(:search_bar)
    }
  end

  @impl true
  def compose(:filter_selector, %{active_filters: active_filters}) do
    %{
      module: Selector,
      params: %{
        items: Admin.UserFilters.labels(active_filters),
        type: :label
      }
    }
  end

  @impl true
  def compose(:search_bar, %{query_string: query_string}) do
    %{
      module: SearchBar,
      params: %{
        query_string: query_string,
        placeholder: dgettext("eyra-admin", "search.placeholder"),
        debounce: "200"
      }
    }
  end

  defp update_users(%{assigns: %{active_filters: filters, query: query, myself: myself}} = socket) do
    users =
      Account.Public.list_internal_users([:profile])
      |> Enum.sort(&(Account.User.label(&1) <= Account.User.label(&2)))
      |> query(filters)
      |> query(query)
      |> Enum.map(&map_to_item(&1, myself))

    assign(socket, users: users)
  end

  defp query(users, nil), do: users
  defp query(users, []), do: users

  defp query(users, query) when is_list(query) do
    users
    |> Enum.filter(&include?(&1, query))
  end

  defp include?(_, []), do: true

  defp include?(user, [term]) do
    include?(user, term)
  end

  defp include?(user, [term | rest]) do
    include?(user, term) and include?(user, rest)
  end

  defp include?(_, ""), do: true

  defp include?(%Account.User{email: email, profile: profile}, word) when is_binary(word) do
    word = String.downcase(word)
    String.contains?(email |> String.downcase(), word) or include?(profile, word)
  end

  defp include?(%Account.User{verified_at: verified_at}, :verified), do: verified_at != nil
  defp include?(%Account.User{creator: creator}, :creator) when not is_nil(creator), do: creator

  defp include?(%Account.UserProfileModel{fullname: fullname}, word)
       when not is_nil(fullname) and is_binary(word) do
    String.contains?(fullname |> String.downcase(), word)
  end

  defp include?(_, _), do: false

  defp map_to_item(%Account.User{} = user, target) do
    photo_url = ImageHelpers.get_photo_url(user.profile)
    info = user_info(user)
    action_verify_button = user_action_verify_button(user, target)
    action_activate_button = user_action_activate_button(user, target)

    %{
      photo_url: photo_url,
      name: user.displayname,
      email: user.email,
      info: info,
      action_buttons: [
        action_activate_button,
        action_verify_button
      ]
    }
  end

  defp user_info(%Account.User{verified_at: nil}), do: ""

  defp user_info(%Account.User{verified_at: verified_at}) do
    "Verified #{Timestamp.humanize(verified_at)}"
  end

  defp user_action_verify_button(%Account.User{creator: false} = user, target) do
    %{
      action: %{type: :send, event: "make_creator", item: user.id, target: target},
      face: %{type: :plain, label: "Make creator", icon: :add}
    }
  end

  defp user_action_verify_button(%Account.User{verified_at: nil} = user, target) do
    %{
      action: %{type: :send, event: "verify_creator", item: user.id, target: target},
      face: %{type: :plain, label: "Verify", icon: :verify}
    }
  end

  defp user_action_verify_button(user, target) do
    %{
      action: %{type: :send, event: "unverify_creator", item: user.id, target: target},
      face: %{type: :plain, label: "Unverify", icon: :unverify}
    }
  end

  defp user_action_activate_button(%Account.User{confirmed_at: nil} = user, target) do
    %{
      action: %{type: :send, event: "activate_user", item: user.id, target: target},
      face: %{type: :plain, label: "Activate", icon: :verify}
    }
  end

  defp user_action_activate_button(user, target) do
    %{
      action: %{type: :send, event: "deactivate_user", item: user.id, target: target},
      face: %{type: :plain, label: "Deactivate", icon: :unverify}
    }
  end

  defp save(socket, user_id_string, attrs) do
    user = Account.Public.get_user!(String.to_integer(user_id_string))
    changeset = Account.User.admin_changeset(user, attrs)
    {:ok, _} = Core.Persister.save(user, changeset)
    socket |> update_users()
  end

  # Events

  @impl true
  def handle_event("make_creator", %{"item" => user_id_string}, socket) do
    {:noreply, socket |> save(user_id_string, %{creator: true})}
  end

  @impl true
  def handle_event("verify_creator", %{"item" => user_id_string}, socket) do
    {
      :noreply,
      socket |> save(user_id_string, %{creator: true, verified_at: NaiveDateTime.utc_now()})
    }
  end

  @impl true
  def handle_event("unverify_creator", %{"item" => user_id_string}, socket) do
    {
      :noreply,
      socket |> save(user_id_string, %{verified_at: nil})
    }
  end

  @impl true
  def handle_event("activate_user", %{"item" => user_id_string}, socket) do
    {
      :noreply,
      socket |> save(user_id_string, %{creator: true, confirmed_at: NaiveDateTime.utc_now()})
    }
  end

  @impl true
  def handle_event("deactivate_user", %{"item" => user_id_string}, socket) do
    {:noreply, socket |> save(user_id_string, %{confirmed_at: nil})}
  end

  @impl true
  def handle_event(
        "search_query",
        %{query: query, query_string: query_string, source: %{name: :search_bar}},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(query: query, query_string: query_string)
      |> update_users()
    }
  end

  @impl true
  def handle_event("active_item_ids", %{active_item_ids: active_filters}, socket) do
    {
      :noreply,
      socket
      |> assign(active_filters: active_filters)
      |> update_users()
      |> update_child(:search_bar)
      |> update_child(:filter_selector)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-admin", "account.title") %> <span class="text-primary"><%= Enum.count(@users) %></span></Text.title2>
        <div class="flex flex-row gap-3 items-center">
          <div class="font-label text-label">Filter:</div>
            <.child name={:filter_selector} fabric={@fabric} />
          <div class="flex-grow" />
          <div class="flex-shrink-0">
            <.child name={:search_bar} fabric={@fabric} />
          </div>
        </div>
        <.spacing value="M" />

        <table class="w-full">
          <%= for user_item <- @users do %>
            <.live_component module={UserListItem} id={user_item.email} user_item={user_item} />
          <% end %>
        </table>
      </Area.content>
    </div>
    """
  end
end
