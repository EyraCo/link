defmodule Systems.Pool.SubmissionView do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.{Title3, Body}
  alias Frameworks.Pixel.Form.{Form, NumberInput, DateInput}

  import CoreWeb.UI.Timestamp,
    only: [
      now: 0,
      one_week_after: 1,
      parse_user_input_date: 1,
      format_user_input_date: 1,
      before?: 2
    ]

  alias Systems.{
    Pool
  }

  prop(props, :any, required: true)

  data(schedule_start_toggle_labels, :list)
  data(schedule_start_disabled, :boolean)

  data(schedule_end_toggle_labels, :list)
  data(schedule_end_disabled, :boolean)

  data(changeset, :any)
  data(focus, :any, default: "")

  defp determine_new_end(_, nil), do: nil
  defp determine_new_end(nil, schedule_end), do: schedule_end

  defp determine_new_end(schedule_start, schedule_end) do
    if before?(schedule_end, schedule_start) do
      format_user_input_date(one_week_after(schedule_start))
    else
      schedule_end
    end
  end

  def update(
        %{active_item_ids: [], selector_id: :schedule_start_toggle},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :ok,
      socket
      |> save(entity, %{schedule_start: nil})
    }
  end

  def update(
        %{active_item_ids: [_], selector_id: :schedule_start_toggle},
        %{assigns: %{entity: entity}} = socket
      ) do
    schedule_start = format_user_input_date(now())
    schedule_end = determine_new_end(schedule_start, entity.schedule_end)

    attrs = %{
      schedule_start: schedule_start,
      schedule_end: schedule_end
    }

    {
      :ok,
      socket
      |> save(entity, attrs)
    }
  end

  def update(
        %{active_item_ids: [], selector_id: :schedule_end_toggle},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :ok,
      socket
      |> save(entity, %{schedule_end: nil})
    }
  end

  def update(
        %{active_item_ids: [_], selector_id: :schedule_end_toggle},
        %{assigns: %{entity: entity}} = socket
      ) do
    base_date =
      case entity.schedule_start do
        nil -> now()
        date -> parse_user_input_date(date)
      end

    schedule_end = format_user_input_date(one_week_after(base_date))
    attrs = %{schedule_end: schedule_end}

    {
      :ok,
      socket
      |> save(entity, attrs)
    }
  end

  # Handle update from parent after attempt to publish
  def update(%{props: %{validate?: new}}, %{assigns: %{validate?: current}} = socket)
      when new != current do
    {
      :ok,
      socket
      |> assign(validate?: new)
      |> validate_for_publish()
    }
  end

  def update(%{id: id, props: %{entity: entity, validate?: validate?}}, socket) do
    %{
      schedule_start: schedule_start,
      schedule_end: schedule_end
    } = entity

    changeset = Pool.SubmissionModel.changeset(entity, %{})

    schedule_start_disabled = schedule_start == nil

    schedule_start_toggle_labels = [
      %{
        id: :schedule_start_toggle,
        value: dgettext("eyra-submission", "schedule.start.label"),
        active: not schedule_start_disabled
      }
    ]

    schedule_end_disabled = schedule_end == nil

    schedule_end_toggle_labels = [
      %{
        id: :schedule_end_toggle,
        value: dgettext("eyra-submission", "schedule.end.label"),
        active: not schedule_end_disabled
      }
    ]

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        schedule_start_toggle_labels: schedule_start_toggle_labels,
        schedule_start_disabled: schedule_start_disabled,
        schedule_end_toggle_labels: schedule_end_toggle_labels,
        schedule_end_disabled: schedule_end_disabled,
        changeset: changeset,
        validate?: validate?
      )
      |> validate_for_publish()
    }
  end

  defp update_ui(
         %{assigns: %{entity: %{schedule_start: schedule_start, schedule_end: schedule_end}}} =
           socket
       ) do
    socket
    |> assign(
      schedule_start_disabled: schedule_start == nil,
      schedule_end_disabled: schedule_end == nil
    )
  end

  # Validate

  def validate_for_publish(%{assigns: %{entity: entity, validate?: true}} = socket) do
    changeset =
      Pool.SubmissionModel.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    socket
    |> assign(changeset: changeset)
  end

  def validate_for_publish(socket), do: socket

  # Saving

  @impl true
  def handle_event("save", %{"submission_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  def save(socket, %Pool.SubmissionModel{} = entity, attrs) do
    changeset = Pool.SubmissionModel.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> validate_for_publish()
    |> update_ui
  end

  def render(assigns) do
    ~F"""
    <ContentArea>
      <Form id={@id} changeset={@changeset} change_event="save" target={@myself} focus={@focus}>
        <Title3 margin="mb-5 sm:mb-8">{dgettext("eyra-submission", "reward.label")}</Title3>
        <NumberInput
          field={:reward_value}
          label_text={dgettext("eyra-submission", "reward.value.label")}
        />
        <Spacing value="M" />

        <Title3 margin="mb-5 sm:mb-8">{dgettext("eyra-submission", "schedule.title")}</Title3>
        <Body>{dgettext("eyra-submission", "schedule.description")}</Body>
        <Spacing value="S" />

        <div class="flex flex-col gap-y-2 sm:flex-row items-left w-full sm:w-form">
          <div class="flex-wrap mt-2">
            <Selector
              id={:schedule_start_toggle}
              items={@schedule_start_toggle_labels}
              type={:checkbox}
              parent={%{type: __MODULE__, id: @id}}
            />
          </div>
          <div class="flex-grow">
          </div>
          <div class="flex-wrap h-full">
            <DateInput field={:schedule_start} disabled={@schedule_start_disabled} />
          </div>
        </div>

        <div class="flex flex-col gap-y-2 sm:flex-row items-left w-full sm:w-form">
          <div class="flex-wrap mt-2">
            <Selector
              id={:schedule_end_toggle}
              items={@schedule_end_toggle_labels}
              type={:checkbox}
              parent={%{type: __MODULE__, id: @id}}
            />
          </div>
          <div class="flex-grow">
          </div>
          <div class="flex-wrap h-full">
            <DateInput field={:schedule_end} disabled={@schedule_end_disabled} />
          </div>
        </div>
      </Form>
    </ContentArea>
    """
  end
end
