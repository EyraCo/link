defmodule EyraUI.Icon do
  @moduledoc """
  Round icon with grey border.

  ## Examples
  ```
  <Icon
    size="L"
    src="test.png"
  />
  ```
  """
  use Surface.Component

  prop(size, :string, required: true)
  prop(src, :string, required: true)
  prop(border_size, :css_class, default: "border-2")

  defp size("L"), do: "w-12 h-12 sm:h-16 sm:w-16 lg:h-84px lg:w-84px"
  defp size("S"), do: "h-14 w-14"

  def render(assigns) do
    ~H"""
    <div class="{{size(@size)}} rounded-full bg-white border-grey4 border-opacity-100 {{@border_size}}">
      <img class="rounded-full w-full h-full" src={{@src}}/>
    </div>
    """
  end
end
