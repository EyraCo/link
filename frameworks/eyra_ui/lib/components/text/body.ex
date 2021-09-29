defmodule EyraUI.Text.Body do
  @moduledoc """
  The body large is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")
  prop(align, :css_class, default: "text-left")

  def render(assigns) do
    ~H"""
    <div class="flex-wrap text-bodymedium sm:text-bodylarge font-body {{@color}} {{@align}}">
      <slot />
    </div>
    """
  end
end
