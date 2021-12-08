defmodule Systems.Assignment.Context do
  @moduledoc """
  The assignment context.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Ecto.Multi
  alias Core.Repo
  alias CoreWeb.UI.Timestamp
  alias Core.Authorization

  alias Systems.{
    Assignment,
    Crew,
    Survey,
    Lab
  }

  @min_expiration_timeout 30

  def get!(id, preload \\ []) do
    from(a in Assignment.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_by_crew!(%{id: crew_id}), do: get_by_crew!(crew_id)
  def get_by_crew!(crew_id) when is_number(crew_id) do
    from(a in Assignment.Model, where: a.crew_id == ^crew_id)
    |> Repo.all()
  end

  def get_by_assignable(assignable, preload \\ [])
  def get_by_assignable(%Assignment.ExperimentModel{id: id}, preload) do
    from(a in Assignment.Model, where: a.assignable_experiment_id == ^id, preload: ^preload)
    |> Repo.one()
  end

  def create(%{} = attrs, crew, experiment, auth_node) do

    assignable_field = assignable_field(experiment)

    %Assignment.Model{}
    |> Assignment.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(assignable_field, experiment)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def copy(%Assignment.Model{} = assignment, %Assignment.ExperimentModel{} = experiment, auth_node) do
    # don't copy crew, just create a new one
    {:ok, crew} = Crew.Context.create(auth_node)

    %Assignment.Model{}
    |> Assignment.Model.changeset(Map.from_struct(assignment))
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:assignable_experiment, experiment)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def create_experiment(%{} = attrs, tool, auth_node) do
    tool_field = Assignment.ExperimentModel.tool_field(tool)

    %Assignment.ExperimentModel{}
    |> Assignment.ExperimentModel.changeset(:create, attrs)
    |> Ecto.Changeset.put_assoc(tool_field, tool)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def copy_experiment(%Assignment.ExperimentModel{} = experiment, %Survey.ToolModel{} = tool, auth_node) do
    %Assignment.ExperimentModel{}
    |> Assignment.ExperimentModel.changeset(:copy, Map.from_struct(experiment))
    |> Ecto.Changeset.put_assoc(:survey_tool, tool)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def copy_experiment(%Assignment.ExperimentModel{} = experiment, %Lab.ToolModel{} = tool, auth_node) do
    %Assignment.ExperimentModel{}
    |> Assignment.ExperimentModel.changeset(:copy, Map.from_struct(experiment))
    |> Ecto.Changeset.put_assoc(:lab_tool, tool)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def owner(%Assignment.Model{} = assignment) do
    owner =
      assignment
      |> Authorization.get_parent_nodes()
      |> List.last()
      |> Authorization.users_with_role(:owner)
      |> List.first()

    case owner do
      nil ->
        Logger.error("No owner role found for assignment #{assignment.id}")
        {:error}
      owner ->
        {:ok, owner}
    end
  end

  def expiration_timestamp(assignment) do
    assignable = Assignment.Model.assignable(assignment)
    duration = Assignment.Assignable.duration(assignable)
    timeout = max(@min_expiration_timeout, duration)

    Timestamp.naive_from_now(timeout)
  end

  def apply_member(id, user) when is_number(id) do
    apply_member(get!(id, [:crew]), user)
  end

  def apply_member(%{crew: crew} = assignment, user) do
    if Crew.Context.member?(crew, user) do
      Crew.Context.get_member!(crew, user)
    else
      expire_at = expiration_timestamp(assignment)
      Crew.Context.apply_member!(crew, user, expire_at)
    end
  end

  def cancel(%Assignment.Model{} = assignment, user) do
    crew = get_crew(assignment)
    Crew.Context.cancel(crew, user)
  end

  def cancel(id, user) do
    get!(id) |> cancel(user)
  end

  def complete_task(%{crew: crew} = _assignment, user) do
    if Crew.Context.expired_member?(crew, user) do nil
    else
      member = Crew.Context.get_member!(crew, user)
      task = Crew.Context.get_task(crew, member)
      Crew.Context.complete_task!(task)
    end
  end

  @doc """
  How many new members can be added to the assignment?
  """
  def open_spot_count(%{crew: _crew} = assignment) do
    type = assignment_type(assignment)
    open_spot_count?(assignment, type)
  end

  @doc """
  Is assignment open for new members?
  """
  def open?(%{crew: _crew} = assignment) do
    open_spot_count(assignment) > 0
  end

  def open?(_), do: true

  defp open_spot_count?(%{crew: crew} = assignment, :one_task) do
    assignable = Assignment.Model.assignable(assignment)
    target = Assignment.Assignable.spot_count(assignable)
    all_non_expired_tasks = Crew.Context.count_tasks(crew, Crew.TaskStatus.values())

    max(0, target - all_non_expired_tasks)
  end

  defp assignment_type(_assignment) do
    # Some logic (eg: open?) is depending on the type of assignment.
    # Currently we only support the 1-task assignment: a member has one task todo.
    # Other types will be:
    #   N-tasks: a member can voluntaraly pick one or more tasks
    #   all-tasks: a member has a batch of tasks todo

    :one_task
  end

  def mark_expired_debug(%{assignable_experiment: %{duration: duration}} = assignment, force) do
    mark_expired_debug(assignment, duration, force)
  end

  def mark_expired_debug(%{crew_id: crew_id}, duration, force) do
    expiration_timeout = max(@min_expiration_timeout, duration)
    task_query =
      if force do
        pending_tasks_query(crew_id)
      else
        expired_pending_tasks_query(crew_id, expiration_timeout)
      end

    member_ids = from(t in task_query, select: t.member_id)
    member_query = from(m in Crew.MemberModel, where: m.id in subquery(member_ids))

    Multi.new()
    |> Multi.update_all(:members , member_query, set: [expired: true])
    |> Multi.update_all(:tasks, task_query, set: [expired: true])
    |> Repo.transaction()
  end

  def pending_tasks_query(crew_id) do
    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew_id and
        t.status == :pending and
        t.expired == false
    )
  end

  def expired_pending_tasks_query(crew_id, expiration_timeout) when is_binary(expiration_timeout) do
    expired_pending_tasks_query(crew_id, String.to_integer(expiration_timeout))
  end

  def expired_pending_tasks_query(crew_id, expiration_timeout) do
    expiration_timestamp =
      Timestamp.now
      |> Timestamp.shift_minutes(expiration_timeout * -1)

    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew_id and
        t.status == :pending and
        t.expired == false and
        (
          t.started_at <= ^expiration_timestamp or
          (
            is_nil(t.started_at) and t.updated_at <= ^expiration_timestamp
          )
        )
    )
  end

  # Crew
  def get_crew(%{crew_id: crew_id} = _assignment) do
    from(
      c in Crew.Model,
      where: c.id == ^crew_id
    )
    |> Repo.one()
  end

  # Assignable

  def ready?(%{assignable_experiment: experiment}) do
    ready?(experiment)
  end

  def ready?(%Assignment.ExperimentModel{} = experiment) do
    changeset =
      %Assignment.ExperimentModel{}
      |> Assignment.ExperimentModel.operational_changeset(Map.from_struct(experiment))

    changeset.valid? && tool_ready?(experiment)
  end

  def tool_ready?(%{survey_tool: tool})when not is_nil(tool), do: Survey.Context.ready?(tool)
  def tool_ready?(%{lab_tool: tool})when not is_nil(tool), do: Lab.Context.ready?(tool)

  defp assignable_field(%Assignment.ExperimentModel{}), do: :assignable_experiment

  # Experiment

  def get_experiment!(id, preload \\ []) do
    from(a in Assignment.ExperimentModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_experiment_by_tool!(%{id: tool_id} = tool, preload \\ []) do
    tool_id_field = Assignment.ExperimentModel.tool_id_field(tool)
    where = [{tool_id_field, tool_id}]

    from(a in Assignment.ExperimentModel,
      where: ^where,
      preload: ^preload
    )
    |> Repo.one!()
  end

end
