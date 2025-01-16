defmodule Systems.Email.Dialog do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text

  alias Systems.{
    Email
  }

  @impl true
  def update(
        %{
          id: id,
          users: users,
          current_user: current_user
        },
        %{assigns: %{myself: myself}} = socket
      ) do
    close_button = %{
      action: %{type: :send, event: "close", target: myself},
      face: %{type: :icon, icon: :close}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        users: users,
        current_user: current_user,
        close_button: close_button
      )
    }
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, update_parent(socket, :close)}
  end

  defp update_parent(socket, message) do
    send(self(), {:email_dialog, message})
    socket
  end

  # data(close_button, :map)

  attr(:users, :list, required: true)
  attr(:current_user, :map, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-w-1/2 max-w-9/10 sm:max-w-3/4 p-8 bg-white shadow-floating rounded">
      <div class="">
        <div class="flex flex-row">
          <div class="flex-grow" />
          <Button.dynamic {@close_button} />
        </div>
        <.spacing value="S" />
        <Text.title2><%= dgettext("eyra-email", "dialog.title") %></Text.title2>
        <.live_component module={Email.Form} id={:email_form} users={@users} from_user={@current_user} />
      </div>
    </div>
    """
  end
end
