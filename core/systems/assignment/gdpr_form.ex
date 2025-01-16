defmodule Systems.Assignment.GdprForm do
  use CoreWeb, :live_component

  alias Frameworks.Pixel
  alias Systems.Assignment
  alias Systems.Consent

  @impl true
  def update(%{id: id, entity: entity}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity
      )
      |> update_status()
      |> compose_child(:switch)
      |> compose_child(:consent_revision_form)
    }
  end

  def update_status(%{assigns: %{confirming_status_off: true}} = socket) do
    socket |> assign(status: :off)
  end

  def update_status(%{assigns: %{entity: %{consent_agreement: consent_agreement}}} = socket) do
    status =
      if consent_agreement do
        :on
      else
        :off
      end

    socket |> assign(status: status)
  end

  @impl true
  def compose(:switch, %{status: status}) do
    %{
      module: Pixel.Switch,
      params: %{
        opt_in?: false,
        on_text: dgettext("eyra-assignment", "gdpr_form.on.label"),
        off_text: dgettext("eyra-assignment", "gdpr_form.off.label"),
        status: status
      }
    }
  end

  @impl true
  def compose(:consent_revision_form, %{entity: %{consent_agreement: nil}}) do
    %{
      module: Consent.RevisionForm,
      params: %{entity: nil}
    }
  end

  @impl true
  def compose(:consent_revision_form, %{entity: %{consent_agreement: consent_agreement}}) do
    %{
      module: Consent.RevisionForm,
      params: %{
        entity: Consent.Public.latest_revision(consent_agreement)
      }
    }
  end

  @impl true
  def compose(:confirmation_modal, %{entity: %{consent_agreement: consent_agreement}}) do
    assigns = %{consent_agreement: consent_agreement}
    signatures = Consent.Public.list_signatures(consent_agreement)

    assigns =
      if signatures != [] do
        Map.put(assigns, :body, dgettext("eyra-assignment", "gdpr_form.confirmation_modal.body"))
      else
        assigns
      end

    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: assigns
      }
    }
  end

  @impl true
  def handle_event(
        "update",
        %{status: :on},
        %{assigns: %{entity: %{auth_node: auth_node} = assignment}} = socket
      ) do
    consent_agreement = Consent.Public.prepare_agreement(auth_node)
    {:ok, _} = Assignment.Public.update_consent_agreement(assignment, consent_agreement)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event(
        "update",
        %{status: :off},
        %{assigns: %{entity: assignment}} = socket
      ) do
    revision = Consent.Public.latest_revision(assignment.consent_agreement)
    localized_default_text = dgettext("eyra-consent", "default.consent.text")

    {
      :noreply,
      socket
      |> handle_off_state(revision, revision.source == localized_default_text)
    }
  end

  @impl true
  def handle_event("cancelled", %{source: %{name: :confirmation_modal}}, socket) do
    {:noreply,
     socket
     |> update_switch(confirming_status_off: false)
     |> hide_modal(:confirmation_modal)}
  end

  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :confirmation_modal}},
        %{assigns: %{entity: assignment}} = socket
      ) do
    {:ok, _} = Assignment.Public.delete_consent_agreement(assignment)

    {
      :noreply,
      socket
      |> assign(confirming_status_off: false)
      |> hide_modal(:confirmation_modal)
    }
  end

  defp handle_off_state(socket, %{source: source}, false) when not is_nil(source) do
    socket
    |> update_switch(confirming_status_off: true)
    |> compose_child(:confirmation_modal)
    |> show_modal(:confirmation_modal, :dialog)
  end

  defp handle_off_state(socket, _, _) do
    {:ok, _} = Assignment.Public.delete_consent_agreement(socket.assigns.entity)
    socket
  end

  @impl true
  def handle_modal_closed(socket, :confirmation_modal) do
    update_switch(socket, confirming_status_off: false)
  end

  defp update_switch(socket, confirming_status_off: confirming_status_off) do
    socket
    |> assign(confirming_status_off: confirming_status_off)
    |> update_status()
    |> compose_child(:switch)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.child name={:switch} fabric={@fabric} />
        <.spacing value="S" />
        <.child name={:consent_revision_form} fabric={@fabric} />
      </div>
    """
  end
end
