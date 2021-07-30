defmodule EyraUI.Button.BackButton do
  @moduledoc """
  A colored button with white text.

  """
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(path, :string, required: true)
  prop(label, :string, required: true)
  prop(icon, :string, default: "/images/back.svg")

  def render(assigns) do
    ~H"""
    <LiveRedirect to={{ @path }} >
      <div class="pt-1 pb-1 active:pt-5px active:pb-3px rounded pl-4 pr-4 bg-opacity-0">
        <div class="flex items-center">
          <div>
              <img class="mr-3 -mt-2px" src={{@icon}}/>
          </div>
          <div class="h-10 focus:outline-none">
            <div class="flex flex-col justify-center h-full items-center">
              <div class="flex-wrap text-grey1 text-button font-button">
                {{ @label }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </LiveRedirect>
    """
  end
end
