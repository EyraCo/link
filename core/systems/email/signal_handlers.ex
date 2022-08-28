defmodule Core.Mailer.SignalHandlers do
  use Frameworks.Signal.Handler
  use Bamboo.Phoenix, view: Systems.Email.EmailView
  import Core.FeatureFlags
  alias Systems.Email
  alias Systems.Notification.Box

  @impl true
  def dispatch(:new_notification, %{box: box, data: %{title: title}}) do
    if feature_enabled?(:notification_mails) do
      for mail <- base_emails(box) do
        mail
        |> subject(title)
        |> render(:new_notification, title: title)
        |> Email.Context.deliver_later()
      end
    end
  end

  defp base_emails(%Box{} = box) do
    box
    |> Core.Authorization.users_with_role(:owner)
    |> Enum.map(&user_email(&1))
  end

  defp user_email(user) do
    Email.Context.base_email() |> to(user.email) |> assign(:user, user)
  end
end