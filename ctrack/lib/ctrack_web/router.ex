defmodule CtrackWeb.Router do
  use CtrackWeb, :router

  import CtrackWeb.Auth.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {CtrackWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  if Application.compile_env(:ctrack, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: CtrackWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", CtrackWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live("/", PageLive)

    scope "/auth" do
      live_session :redirect_if_user_is_authenticated,
        on_mount: [{CtrackWeb.Auth.UserAuth, :redirect_if_user_is_authenticated}] do
        live("/users/register", UserRegistrationLive, :new)
        live("/users/log_in", UserLoginLive, :new)
        live("/users/reset_password", UserForgotPasswordLive, :new)
        live("/users/reset_password/:token", UserResetPasswordLive, :edit)
      end

      post("/users/log_in", UserSessionController, :create)
    end
  end

  scope "/", CtrackWeb do
    pipe_through([:browser, :require_authenticated_user])

    live("/home", Home)

    scope "/auth" do
      live_session :require_authenticated_user,
        on_mount: [{CtrackWeb.Auth.UserAuth, :ensure_authenticated}] do
        live("/users/settings", UserSettingsLive, :edit)
        live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
      end
    end
  end

  scope "/auth", CtrackWeb do
    pipe_through([:browser])

    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [{CtrackWeb.Auth.UserAuth, :mount_current_user}] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end
end
