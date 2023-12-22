defmodule Systems.Assignment.ContentPageBuilder do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  alias Systems.{
    Assignment,
    Project,
    Workflow,
    Support
  }

  def view_model(
        %{id: id, special: special} = assignment,
        assigns
      ) do
    title = get_title(special)
    show_errors = show_errors(assignment, assigns)
    tabs = create_tabs(assignment, show_errors, assigns)
    action_map = action_map(assignment, assigns)
    actions = actions(assignment, action_map)

    %{
      id: id,
      title: title,
      tabs: tabs,
      actions: actions,
      show_errors: show_errors
    }
  end

  defp get_title(nil) do
    dgettext("eyra-assignment", "content.title")
  end

  defp get_title(special) do
    Assignment.Templates.translate(special)
  end

  defp show_errors(_, _) do
    # concept? = status == :concept
    # publish_clicked or not concept?
    false
  end

  defp action_map(assignment, %{current_user: %{id: user_id}}) do
    preview_url = Assignment.Private.get_preview_url(assignment, user_id)

    preview_action = %{type: :http_get, to: preview_url, target: "_blank"}
    publish_action = %{type: :send, event: "action_click", item: :publish}
    retract_action = %{type: :send, event: "action_click", item: :retract}
    close_action = %{type: :send, event: "action_click", item: :close}
    open_action = %{type: :send, event: "action_click", item: :open}

    %{
      preview: %{
        label: %{
          action: preview_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "preview.button"),
            bg_color: "bg-primary"
          }
        },
        icon: %{
          action: preview_action,
          face: %{type: :icon, icon: :preview, alt: dgettext("eyra-assignment", "preview.button")}
        }
      },
      publish: %{
        label: %{
          action: publish_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "publish.button"),
            bg_color: "bg-success"
          }
        },
        icon: %{
          action: publish_action,
          face: %{type: :icon, icon: :preview, alt: dgettext("eyra-assignment", "preview.button")}
        },
        handle_click: &handle_publish/1
      },
      retract: %{
        label: %{
          action: retract_action,
          face: %{
            type: :secondary,
            label: dgettext("eyra-assignment", "retract.button"),
            text_color: "text-error",
            border_color: "border-error"
          }
        },
        icon: %{
          action: retract_action,
          face: %{
            type: :icon,
            icon: :retract,
            alt: dgettext("eyra-benchmark", "assignment.button")
          }
        },
        handle_click: &handle_retract/1
      },
      close: %{
        label: %{
          action: close_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "close.button")
          }
        },
        icon: %{
          action: close_action,
          face: %{type: :icon, icon: :close, alt: dgettext("eyra-assignment", "close.button")}
        },
        handle_click: &handle_close/1
      },
      open: %{
        label: %{
          action: open_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "open.button")
          }
        },
        icon: %{
          action: open_action,
          face: %{type: :icon, icon: :open, alt: dgettext("eyra-assignment", "open.button")}
        },
        handle_click: &handle_open/1
      }
    }
  end

  defp actions(%{status: :online}, %{retract: retract}), do: [retract: retract]

  defp actions(%{status: :offline}, %{publish: publish, close: close}),
    do: [publish: publish, close: close]

  defp actions(%{status: :idle}, %{open: open}), do: [open: open]

  defp actions(%{status: _concept}, %{publish: publish, preview: preview}),
    do: [publish: publish, preview: preview]

  defp handle_publish(socket) do
    socket |> set_status(:online)
  end

  defp handle_retract(socket) do
    socket |> set_status(:offline)
  end

  defp handle_close(socket) do
    socket |> set_status(:idle)
  end

  defp handle_open(socket) do
    socket |> set_status(:concept)
  end

  defp set_status(%{assigns: %{model: assignment}} = socket, status) do
    assignment = Assignment.Public.update!(assignment, %{status: status})
    socket |> Phoenix.Component.assign(model: assignment)
  end

  defp create_tabs(assignment, show_errors, assigns) do
    get_tab_keys()
    |> Enum.map(&create_tab(&1, assignment, show_errors, assigns))
  end

  defp get_tab_keys() do
    [:config, :items]
  end

  defp create_tab(
         :config,
         assignment,
         show_errors,
         %{fabric: fabric, uri_origin: uri_origin, viewport: viewport, breakpoint: breakpoint} =
           _assigns
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :settings_form, Assignment.SettingsView, %{
        entity: assignment,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      })

    %{
      id: :settings_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.settings"),
      forward_title: dgettext("eyra-project", "tabbar.item.settings.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :items,
         %{workflow: workflow},
         show_errors,
         %{
           current_user: user,
           uri_origin: uri_origin
         }
       ) do
    ready? = false

    %{
      id: :workflow_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-workflow", "tabbar.item.workflow"),
      forward_title: dgettext("eyra-workflow", "tabbar.item.workflow.forward"),
      type: :fullpage,
      live_component: Workflow.BuilderView,
      props: %{
        user: user,
        uri_origin: uri_origin,
        workflow: workflow,
        config: %{
          director: :assignment,
          list: %{
            title: dgettext("eyra-workflow", "item.list.title"),
            description: dgettext("eyra-workflow", "item.list.description")
          },
          library: %{
            title: dgettext("eyra-workflow", "item.library.title"),
            description: dgettext("eyra-workflow", "item.library.description"),
            items: [
              %{
                id: :donate,
                type: :feldspar_tool,
                title: dgettext("eyra-workflow", "item.donate.title"),
                description: dgettext("eyra-workflow", "item.donate.description")
              },
              %{
                id: :questionnaire,
                type: :alliance_tool,
                title: dgettext("eyra-workflow", "item.questionnaire.title"),
                description: dgettext("eyra-workflow", "item.questionnaire.description")
              },
              %{
                id: :request,
                type: :document_tool,
                title: dgettext("eyra-workflow", "item.request.title"),
                description: dgettext("eyra-workflow", "item.request.description")
              },
              %{
                id: :download,
                type: :document_tool,
                title: dgettext("eyra-workflow", "item.download.title"),
                description: dgettext("eyra-workflow", "item.download.description")
              }
            ]
          }
        }
      }
    }
  end

  defp create_tab(
         :support,
         assignment,
         _show_errors,
         _assigns
       ) do
    %{
      id: :support,
      title: dgettext("eyra-project", "tabbar.item.support"),
      forward_title: dgettext("eyra-project", "tabbar.item.support.forward"),
      type: :fullpage,
      live_component: Support.Form,
      props: %{
        entity: assignment
      }
    }
  end

  defp create_tab(
         :monitor,
         assignment,
         _show_errors,
         _assigns
       ) do
    %{
      id: :monitor,
      title: dgettext("eyra-project", "tabbar.item.monitor"),
      forward_title: dgettext("eyra-project", "tabbar.item.monitor.forward"),
      type: :fullpage,
      live_component: Project.ItemMonitorView,
      props: %{
        entity: assignment
      }
    }
  end
end
