defmodule Systems.Admin.ImportRewardsPage do
  use Systems.Content.Composer, :live_workspace
  use CoreWeb.FileUploader, accept: ~w(.csv)

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Selector

  alias Systems.Account
  alias Systems.Advert
  alias Systems.Admin
  alias Systems.Student
  alias Systems.Org

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {path, _url, original_filename}
      ) do
    changeset =
      entity
      |> Admin.ImportRewardsModel.changeset(%{session_key: Path.rootname(original_filename)})

    socket
    |> assign(
      changeset: changeset,
      lines_error: [],
      lines_unknown: [],
      lines_valid: [],
      local_file: path,
      uploaded_file: original_filename,
      active_menu_item: :admin
    )
  end

  @impl true
  def get_model(_params, _session, _socket) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(%{"back" => back}, _session, socket) do
    entity = %Admin.ImportRewardsModel{}

    changeset =
      entity
      |> Admin.ImportRewardsModel.changeset(%{})

    process_button = %{
      action: %{
        type: :send,
        event: "process"
      },
      face: %{
        type: :secondary,
        border_color: "bg-tertiary",
        text_color: "text-tertiary",
        label: "Start session"
      }
    }

    import_button = %{
      action: %{
        type: :send,
        event: "import_all"
      },
      face: %{
        type: :primary,
        label: "Import all"
      }
    }

    currency_labels =
      Org.Public.list_nodes(:student_course, ["vu", ":2021"])
      |> Enum.map(&Student.Course.currency(&1.identifier))
      |> Enum.map(&%{id: &1, value: &1, active: false})

    {
      :ok,
      socket
      |> assign(
        local_file: nil,
        entity: entity,
        changeset: changeset,
        process_button: process_button,
        import_button: import_button,
        currency_labels: currency_labels,
        back_path: back,
        lines_valid: [],
        lines_unknown: [],
        lines_error: []
      )
      |> init_file_uploader(:csv)
      |> compose_child(:currency)
    }
  end

  @impl true
  def compose(:currency, %{currency_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :radio,
        background: :dark
      }
    }
  end

  def filter_ok({:ok, _}), do: true
  def filter_ok(_), do: false

  def filter_valid(%{:status => :ready_to_import}), do: true
  def filter_valid(%{:status => :incorrect_currency}), do: true
  def filter_valid(%{:status => :transaction_exists}), do: true
  def filter_valid(_), do: false

  def filter_unknown(%{:status => :unknown}), do: true
  def filter_unknown(_), do: false

  def filter_error({:error, _}), do: true
  def filter_error(_), do: false

  def map({:ok, line}), do: line
  def map({:error, message}), do: message

  def validate(%{"email" => email, "student_id" => student_id} = line, socket) do
    if user = Core.SurfConext.get_user_by_student_id(student_id) do
      IO.puts("User found by student_id! #{user.id}")
      line |> validate(user, socket)
    else
      if user = Account.Public.get_user_by_email(email) do
        IO.puts("User found by email! #{user.id}")
        line |> validate(user, socket)
      else
        line |> Map.put(:status, :unknown)
      end
    end
  end

  def validate(
        %{"credits" => credits} = line,
        user,
        %{assigns: %{session_key: session_key, currency: currency}} = _socket
      ) do
    {status, message} =
      if Advert.Public.user_has_currency?(user, currency) do
        handle_user_has_currency(user, session_key, credits)
      else
        {:incorrect_currency, "Student is not part of #{currency}"}
      end

    line
    |> Map.put(:status, status)
    |> Map.put(:message, message)
    |> Map.put(:user_id, user.id)
  end

  defp handle_user_has_currency(user, session_key, credits) do
    if transaction_exists?(user, session_key) do
      {:transaction_exists, "Import done"}
    else
      if credits <= 0 do
        {:zero_credits, "Zero credits"}
      else
        {:ready_to_import, ""}
      end
    end
  end

  defp transaction_exists?(user, session_key) do
    Advert.Public.import_participant_reward_exists?(user.id, session_key)
  end

  defp process(%{assigns: %{local_file: local_file}} = socket) do
    lines =
      local_file
      |> File.stream!()
      |> CSV.decode(headers: true)

    lines_error =
      lines
      |> Enum.filter(&filter_error(&1))
      |> Enum.map(&map(&1))

    lines_ok =
      lines
      |> Enum.filter(&filter_ok(&1))
      |> Enum.map(&map(&1))
      |> Enum.map(&validate(&1, socket))

    lines_valid =
      lines_ok
      |> Enum.filter(&filter_valid(&1))

    lines_unknown =
      lines_ok
      |> Enum.filter(&filter_unknown(&1))

    socket
    |> assign(
      lines_error: lines_error,
      lines_unknown: lines_unknown,
      lines_valid: lines_valid
    )
  end

  defp import_all(%{assigns: %{lines_valid: lines_valid}} = socket) do
    lines_valid
    |> Enum.filter(&(&1.status == :ready_to_import))
    |> Enum.each(&import_single(socket, &1))

    socket
    |> process()
  end

  defp import_single(%{assigns: %{lines_valid: lines_valid}} = socket, index)
       when is_integer(index) do
    line = lines_valid |> Enum.at(index)

    socket
    |> import_single(line)
    |> process()
  end

  defp import_single(
         %{assigns: %{session_key: session_key, currency: currency}} = socket,
         %{:user_id => user_id, "credits" => credits} = _line
       ) do
    credits = String.to_integer(credits)
    Advert.Public.import_participant_reward(user_id, credits, session_key, currency)

    socket
  end

  @impl true
  def handle_event("active_item_id", %{active_item_id: currency}, socket) do
    {:noreply, socket |> assign(currency: currency)}
  end

  @impl true
  def handle_event("import_all", _params, socket) do
    {
      :noreply,
      socket
      |> import_all()
    }
  end

  @impl true
  def handle_event("import_single", %{"item" => index} = _params, socket) do
    {
      :noreply,
      socket
      |> import_single(index |> String.to_integer())
    }
  end

  @impl true
  def handle_event("process", _params, %{assigns: %{changeset: changeset}} = socket) do
    socket =
      case Ecto.Changeset.apply_action(changeset, :update) do
        {:ok, entity} ->
          socket
          |> assign(entity: entity, session_key: entity.session_key)
          |> process()

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change",
        %{"import_rewards_model" => %{"session_key" => session_key}},
        %{assigns: %{entity: entity}} = socket
      ) do
    changeset = entity |> Admin.ImportRewardsModel.changeset(%{session_key: session_key})

    socket =
      case Ecto.Changeset.apply_action(changeset, :update) do
        {:ok, entity} ->
          socket |> assign(changeset: changeset, entity: entity)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  defp message_color(%{status: :incorrect_currency}), do: "text-delete"
  defp message_color(%{status: :transaction_exists}), do: "text-grey1"
  defp message_color(%{status: :zero_credits}), do: "text-warning"
  defp message_color(_), do: "text-grey1"

  defp opacity(%{status: :transaction_exists}), do: "opacity-30"
  defp opacity(_), do: "opacity-100"

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title="Import rewards" menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
      <Margin.y id={:page_top} />
      <Area.content>
        <Panel.flat bg_color="bg-grey1">
          <.form id="import_form" :let={form} for={@changeset} phx-change="change" phx-target="" >
            <Text.title3 color="text-white">Setup the import session</Text.title3>
            <.spacing value="XXS" />
            <Text.body_large color="text-white">Selected file: <span class="text-tertiary"><%= @uploaded_file %></span></Text.body_large>
            <.spacing value="S" />
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <Button.primary_label
                  label="Select csv file"
                  field={@uploads.csv.ref}
                  bg_color="bg-tertiary"
                  text_color="text-grey1"
                />
                <div class="hidden">
                  <.live_file_input upload={@uploads.csv} />
                </div>
              </div>
            </div>
            <%= if @local_file do %>
              <div class="flex-wrap">
                <.spacing value="M" />
                <.text_input form={form}
                  field={:session_key}
                  label_text="Session key"
                  background={:dark}
                  label_color="text-white"
                />
                <.spacing value="XS" />
                <Text.title6 color="text-white">Currency</Text.title6>
                <.spacing value="XS" />
                <.child name={:currency} fabric={@fabric} />
                <.spacing value="L" />
                <.wrap>
                  <Button.dynamic {@process_button} />
                </.wrap>
              </div>
            <% end %>
          </.form>
        </Panel.flat>
        <.spacing value="L" />
        <%= if Enum.count(@lines_valid) > 0 do %>
          <div>
            <.spacing value="XL" />
            <Text.title2 margin="mb-0">Credit transactions</Text.title2>
            <.spacing value="S" />
            <Panel.flat>
              <table>
                <tr>
                  <td class="pr-4"><Text.body_large>Session key</Text.body_large></td>
                  <td><Text.body_large><span class="text-primary font-button"><%= @session_key %></span></Text.body_large></td>
                </tr>
                <tr>
                  <td class="pr-4"><Text.body_large>Study year</Text.body_large></td>
                  <td><Text.body_large><span class="text-primary font-button"><%= @currency %></span></Text.body_large></td>
                </tr>
              </table>
            </Panel.flat>
            <.spacing value="L" />
            <table class="table-fixed">
              <thead>
                <tr class="text-left">
                  <th class="pl-0 pr-8"><Text.title6>Email</Text.title6></th>
                  <th class="pl-0 pr-8"><Text.title6>Student ID</Text.title6></th>
                  <th class="pl-0 pr-8"><Text.title6>Credits</Text.title6></th>
                  <th class="pl-0" />
                </tr>
              </thead>
              <tbody>
                <%= for {line, index} <- Enum.with_index(@lines_valid) do %>
                  <tr class={"#{opacity(line)} h-10"}>
                    <td class="pr-8"><Text.body_large><%= line["email"] %></Text.body_large></td>
                    <td class="pr-8"><Text.body_large><%= line["student_id"] %></Text.body_large></td>
                    <td class="pr-8"><Text.body_large><%= line["credits"] %></Text.body_large></td>
                    <td class="pr-8">
                      <%= if line.status == :ready_to_import do %>
                        <Button.dynamic {%{
                            action: %{type: :send, event: "import_single", item: index},
                            face: %{type: :icon, icon: :add}
                          }}
                        />
                      <% end %>
                      <Text.body_large color={message_color(line)}><%= line.message %></Text.body_large>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
            <.spacing value="L" />
            <.wrap>
              <Button.dynamic {@import_button} />
            </.wrap>
            <.spacing value="L" />
          </div>
        <% end %>
        <%= if Enum.count(@lines_error) > 0 do %>
          <div>
            <Text.title3>Parsing errors</Text.title3>
            <%= for message <- @lines_error do %>
              <Text.body_large><%= message %></Text.body_large>
            <% end %>
            <.spacing value="M" />
          </div>
        <% end %>
        <.spacing value="M" />
        <%= if Enum.count(@lines_unknown) > 0 do %>
          <div>
            <Text.title3>Unknown students</Text.title3>
            <%= for line <- @lines_unknown do %>
              <Text.body_large><%= line["email"] %></Text.body_large>
            <% end %>
            <.spacing value="M" />
          </div>
        <% end %>
        <Button.back label="Back" path={@back_path} />
      </Area.content>
    </.live_workspace>
    """
  end
end
