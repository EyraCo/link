defmodule EyraUI.Catalogue.Button.Primary.Playground do
  use Surface.Catalogue.Playground,
    subject: EyraUI.Button.PrimaryButton,
    catalogue: EyraUI.Catalogue,
    height: "110px",
    container: {:div, class: "buttons is-centered"}

  data(props, :map,
    default: %{
      to: "/",
      label: "My Button"
    }
  )

  def render(assigns) do
    ~H"""
    <PrimaryButton :props={{ @props }} />
    """
  end
end
