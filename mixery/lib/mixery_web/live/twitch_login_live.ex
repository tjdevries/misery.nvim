defmodule MixeryWeb.Auth.TwitchLoginLive do
  use MixeryWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm mt-40">
      <div class="text-center text-gray-100 font-extrabold">
        Sign in to account
      </div>

      <div class="mt-10">
        <div class="mt-6">
          <.link
            navigate={~p"/auth/twitch"}
            class="flex w-full items-center justify-center gap-3 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-visible:ring-transparent"
          >
            <svg
              class="h-5 w-5 fill-[#9147ff]"
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              fill="currentColor"
              viewBox="0 0 16 16"
            >
              <path d="M3.857 0 1 2.857v10.286h3.429V16l2.857-2.857H9.57L14.714 8V0zm9.714 7.429-2.285 2.285H9l-2 2v-2H4.429V1.143h9.142z" />
              <path d="M11.857 3.143h-1.143V6.57h1.143zm-3.143 0H7.571V6.57h1.143z" />
            </svg>
            <span class="text-sm font-semibold leading-6">Twitch</span>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
