defmodule Systems.Graphite.ToolView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Line

  alias Systems.Graphite

  @impl true
  def update(%{tool: tool, user: user, timezone: timezone}, socket) do
    {
      :ok,
      socket
      |> assign(
        tool: tool,
        user: user,
        timezone: timezone
      )
      |> send_event(:parent, "tool_initialized")
      |> update_submission()
      |> update_open_for_submissions()
      |> update_leaderboard_description()
      |> update_leaderboard_button()
      |> update_done_button()
      |> compose_child(:submission_form)
    }
  end

  defp update_submission(%{assigns: %{tool: tool, user: user}} = socket) do
    submission = Graphite.Public.get_submission(tool, user, :owner)
    assign(socket, submission: submission)
  end

  defp update_open_for_submissions(%{assigns: %{tool: tool}} = socket) do
    socket
    |> assign(open_for_submissions?: Graphite.Public.open_for_submissions?(tool))
  end

  defp update_leaderboard_description(socket) do
    leaderboard_description = dgettext("eyra-graphite", "leaderboard.description")
    assign(socket, leaderboard_description: leaderboard_description)
  end

  defp update_leaderboard_button(
         %{
           assigns: %{
             open_for_submissions?: false,
             tool: %{leaderboard: %{status: :online, id: leaderboard_id}}
           }
         } = socket
       ) do
    leaderboard_button = %{
      action: %{
        type: :http_get,
        to: ~p"/graphite/leaderboard/#{leaderboard_id}",
        target: "_blank"
      },
      face: %{
        type: :plain,
        icon: :forward,
        label: dgettext("eyra-graphite", "leaderboard.goto.button")
      }
    }

    assign(socket, leaderboard_button: leaderboard_button)
  end

  defp update_leaderboard_button(socket) do
    assign(socket, leaderboard_button: nil)
  end

  defp update_done_button(socket) do
    done_button = %{
      action: %{type: :send, event: "done"},
      face: %{type: :primary, label: dgettext("eyra-ui", "done.button")}
    }

    assign(socket, done_button: done_button)
  end

  @impl true
  def compose(:submission_form, %{
        tool: tool,
        user: user,
        open_for_submissions?: open_for_submissions?,
        timezone: timezone
      }) do
    %{
      module: Systems.Graphite.SubmissionForm,
      params: %{
        tool: tool,
        user: user,
        open?: open_for_submissions?,
        timezone: timezone
      }
    }
  end

  @impl true
  def handle_event("go_to_leaderboard", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("done", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-graphite", "submission.title") %></Text.title2>
          <.spacing value="M" />
          <div class="border-grey4 border-2 rounded p-6">
            <.child name={:submission_form} fabric={@fabric} />
            <.spacing value="M" />
            <.line />
            <.spacing value="M" />

            <Text.title3><%= dgettext("eyra-graphite", "leaderboard.title") %></Text.title3>
            <.spacing value="XS" />

            <%= if feature_enabled?(:leaderboard) and @leaderboard_button do %>
              <Text.body><%= dgettext("eyra-graphite", "leaderboard.published.message") %></Text.body>
              <.spacing value="S" />
              <Button.dynamic_bar buttons={[@leaderboard_button]} />
            <% else %>
              <Text.body><%= @leaderboard_description %></Text.body>
              <.spacing value="XS" />
            <% end %>
          </div>
          <.spacing value="M" />

          <%= if @done_button do %>
            <Button.dynamic_bar buttons={[@done_button]} />
          <% end %>
        </Area.content>
     </div>
    """
  end
end
