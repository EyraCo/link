defmodule Systems.DataDonation.Routes do
  defmacro routes() do
    quote do
      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser, :require_authenticated_user])

        live("/:id/content", ContentPage)

        get("/:id/download", DownloadController, :download_all)
        get("/:id/download/:donation_id", DownloadController, :download_single)
      end

      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser])

        get("/:id/donate/:participant", DefaultController, :create)
        get("/donate/:id/:participant", DefaultController, :donate)
        live("/donate/:id", DonatePage)

        get("/flow/:id/:participant", DefaultController, :flow)
        live("/flow/:id", FlowPage)

        live("/thanks/:id/:participant", ThanksPage)
        live("/thankswhatsapp/:id/:participant", ThanksWhatsappPage)

        get("/centerdata/:id", CenterdataController, :create)
        live("/centerdata/fakeapi/page", CenterdataFakeApiPage)
      end

      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser_unprotected])
        post("/centerdata/:id", CenterdataController, :create)
      end
    end
  end
end
