defmodule Systems.Workflow.ItemModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  alias Frameworks.Concept

  import Ecto.Changeset
  alias Systems.Workflow

  schema "workflow_items" do
    field(:group, :string)
    field(:position, :integer)
    field(:title, :string)
    field(:description, :string)

    belongs_to(:workflow, Workflow.Model)
    belongs_to(:tool_ref, Workflow.ToolRefModel)

    timestamps()
  end

  @fields ~w(group position title description)a
  @required_fields ~w(position title description)a

  def changeset(item, params) do
    item
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(item) do
    changeset =
      changeset(item, %{})
      |> validate()

    changeset.valid? && tool_ready?(item)
  end

  defp tool_ready?(%{tool_ref: tool_ref}) do
    Workflow.ToolRefModel.flatten(tool_ref)
    |> Concept.ToolModel.ready?()
  end

  def status(%Workflow.ItemModel{} = item) do
    if ready?(item) do
      :incomplete
    else
      :ready
    end
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :tool_ref
      ])

  def preload_graph(:tool_ref), do: [tool_ref: Workflow.ToolRefModel.preload_graph(:down)]

  def external_path(%{tool_ref: tool_ref}, next_id),
    do: Workflow.ToolRefModel.external_path(tool_ref, next_id)

  def flatten(%{tool_ref: tool_ref}), do: Workflow.ToolRefModel.flatten(tool_ref)
end
