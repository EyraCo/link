defmodule CoreWeb.LiveForm do
  defmacro __using__(_opts) do
    quote do
      use CoreWeb.UI.LiveComponent

      def update(%{focus: focus}, socket) do
        {
          :ok,
          socket
          |> assign(focus: focus)
        }
      end

      def handle_event("focus", %{"field" => field}, socket) do
        claim_focus(socket)

        {
          :noreply,
          socket
          |> assign(focus: field)
        }
      end

      def hide_flash(socket) do
        send(self(), :hide_flash)
        socket
      end

      def flash_error(socket) do
        send(self(), {:flash, :error})
        socket
      end

      def flash_error(socket, message) do
        send(self(), {:flash, :error, message})
        socket
      end

      def save(socket, changeset) do
        socket
        |> hide_flash()

        case Ecto.Changeset.apply_action(changeset, :update) do
          {:ok, entity} ->
            handle_success(socket, changeset, entity)

          {:error, %Ecto.Changeset{} = changeset} ->
            handle_validation_error(socket, changeset)
        end
      end

      defp handle_validation_error(socket, changeset) do
        socket
        |> assign(changeset: changeset)
        |> flash_error()
      end

      defp handle_success(socket, changeset, entity) do
        auto_save(changeset)

        socket
        |> assign(:entity, entity)
        |> assign(:changeset, changeset)
      end

      defp auto_save(changeset) do
        send(self(), {:auto_save, changeset})
      end

      defp claim_focus(%{assigns: %{id: id}}) do
        IO.puts("CLAIM XY")

        send(self(), {:claim_focus, id})
      end
    end
  end
end
