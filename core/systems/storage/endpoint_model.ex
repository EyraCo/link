defmodule Systems.Storage.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Frameworks.Concept

  alias Systems.{
    Storage
  }

  require Storage.BackendTypes

  schema "storage_endpoints" do
    belongs_to(:aws, Storage.AWS.EndpointModel, on_replace: :delete)
    belongs_to(:azure, Storage.Azure.EndpointModel, on_replace: :delete)
    belongs_to(:centerdata, Storage.Centerdata.EndpointModel, on_replace: :delete)
    belongs_to(:yoda, Storage.Yoda.EndpointModel, on_replace: :delete)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields
  @special_fields ~w(aws azure centerdata yoda)a

  def changeset(endpoint, params) do
    endpoint
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: @special_fields

  def reset_special(endpoint, special_field, special) when is_atom(special_field) do
    specials =
      Enum.map(
        @special_fields,
        &{&1,
         if &1 == special_field do
           special
         else
           nil
         end}
      )

    changeset(endpoint, %{})
    |> then(
      &Enum.reduce(specials, &1, fn {field, value}, changeset ->
        put_assoc(changeset, field, value)
      end)
    )
  end

  def special(endpoint) do
    Enum.reduce(@special_fields, nil, fn field, acc ->
      if special = Map.get(endpoint, field) do
        special
      else
        acc
      end
    end)
  end

  def special_field(endpoint) do
    Enum.reduce(@special_fields, nil, fn field, acc ->
      field_id = String.to_existing_atom("#{field}_id")

      if Map.get(endpoint, field_id) != nil do
        field
      else
        acc
      end
    end)
  end

  def ready?(endpoint) do
    if special = special(endpoint) do
      Concept.ContentModel.ready?(special)
    else
      false
    end
  end

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage
    def form(_), do: Storage.EndpointForm
    def ready?(endpoint), do: Storage.EndpointModel.ready?(endpoint)
  end
end
