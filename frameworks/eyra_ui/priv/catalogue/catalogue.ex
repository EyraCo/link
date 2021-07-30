defmodule EyraUI.Catalogue do
  @moduledoc """
  Catalogue implementation for EyraUI.
  """

  use Surface.Catalogue

  load_asset("assets/js/app.js", as: :app_js)
  load_asset("assets/css/app.css", as: :app_css)

  @impl true
  def config() do
    [
      head_css: """
      <script type="text/javascript">#{@app_js}</script>
      <style>#{@app_css}</style>
      """,
      playground: [
        body: [
          style: "padding: 1.5rem; height: 100%;",
          class: "has-background-light"
        ]
      ]
    ]
  end
end
