efmodule EyraUI.Catalogue.Button.PrimaryButton.Example do
  use Surface.Catalogue.Example,
    subject: EyraUI.Button.PrimaryButton,
    catalogue: EyraUI.Catalogue,
    title: "Label",
    height: "90px",
    container: {:div, class: "buttons"}

  def render(assigns) do
    ~H"""
    <PrimaryButton to="/" label="Label"/>
    """
  end
end
