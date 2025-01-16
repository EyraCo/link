defmodule Systems.Pool.SubmissionPage do
  @moduledoc """
   The submission page for a advert.
  """
  use Systems.Content.Composer, :live_workspace

  use Gettext, backend: CoreWeb.Gettext
  import CoreWeb.UI.Member
  import Frameworks.Pixel.Navigation, only: [button_bar: 1]
  import Frameworks.Pixel.Content

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text
  alias Systems.Pool

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Pool.Public.get_submission!(String.to_integer(id),
      pool: Pool.Model.preload_graph([:org, :currency])
    )
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("publish", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    socket =
      if ready_for_publish?(submission) do
        {:ok, _} =
          Pool.Public.update(submission, %{status: :accepted, accepted_at: Timestamp.naive_now()})

        title = dgettext("eyra-submission", "publish.success.title")
        text = dgettext("eyra-submission", "publish.success.text")

        socket
        |> inform(title, text)
      else
        title = dgettext("eyra-submission", "publish.error.title")
        text = dgettext("eyra-submission", "publish.error.text")

        socket
        |> inform(title, text)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("retract", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    {:ok, _} = Pool.Public.update(submission, %{status: :idle})

    title = dgettext("eyra-submission", "retract.admin.success.title")
    text = dgettext("eyra-submission", "retract.admin.success.text")

    {
      :noreply,
      socket
      |> inform(title, text)
    }
  end

  @impl true
  def handle_event("complete", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    {:ok, _} =
      Pool.Public.update(submission, %{status: :completed, completed_at: Timestamp.naive_now()})

    title = dgettext("eyra-submission", "complete.admin.success.title")
    text = dgettext("eyra-submission", "complete.admin.success.text")

    {
      :noreply,
      socket
      |> assign(accepted?: false)
      |> inform(title, text)
    }
  end

  defp ready_for_publish?(submission) do
    changeset =
      Pool.SubmissionModel.operational_changeset(submission, %{})
      |> Pool.SubmissionModel.operational_validation()

    changeset.valid?
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={dgettext("link-studentpool", "submission.title")} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <%= if @vm.member do %>
            <.member {@vm.member} />
          <% end %>
          <.spacing value="XL" />
          <Text.title1><%= @vm.title %></Text.title1>
          <.spacing value="L" />
          <Text.sub_head><%= @vm.byline %></Text.sub_head>
          <.spacing value="L" />
        </Area.content>

        <%= if Map.has_key?(@vm, :form) do %>
          <.live_component
            id={:submission_pool_form}
            module={@vm.form.component}
            {@vm.form.props}
          />
        <% end %>

        <%= if Enum.count(@vm.excluded_adverts) > 0 do %>
          <Area.content>
            <Text.title3 margin="mb-5 sm:mb-8"><%= dgettext("link-studentpool", "excluded.adverts.title") %></Text.title3>
            <.list items={@vm.excluded_adverts} />
            <.spacing value="M" />
          </Area.content>
        <% end %>

        <.spacing value="S" />

        <.live_component
          id={:submission_form}
          module={Pool.SubmissionView}
          submission={@vm.submission}
          validate?={@vm.validate?}
        />
      </div>
      <Area.content>
        <Margin.y id={:button_bar_top} />
        <.button_bar buttons={@vm.actions} />
      </Area.content>
    </.live_workspace>
    """
  end
end
