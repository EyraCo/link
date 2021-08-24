defmodule Mix.Tasks.Email.Test do
  use Mix.Task

  @shortdoc "Send an email directly"
  def run([email]) do
    :application.ensure_all_started(:core)

    user = Core.Factories.build(:member, %{email: email})

    Core.Accounts.Email.account_created(user)
    |> Core.Mailer.deliver_now!()
  end
end
