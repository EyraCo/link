defmodule Systems.Org.Internals do
  defmacro __using__(_opts) do
    quote do
      alias Systems.Org

      require Org.Types

      alias Org.NodeModel, as: Node
      alias Org.LinkModel, as: Link
      alias Org.Types
      alias Org.UserAssociation
    end
  end
end
