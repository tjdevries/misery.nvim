defmodule MixeryWeb.ErrorLive do
  use MixeryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # try do
    #   ThisWillError.error1()
    # rescue
    #   my_exception ->
    #     Sentry.capture_exception(my_exception, stacktrace: __STACKTRACE__)
    # end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # <div class={@key}>What??</div>

    ~H"""
    <div>
      <div>Should Not Be Possible</div>
    </div>
    """
  end

  attr :x, :integer, required: true
  attr :y, :integer, required: true
  attr :title, :string, required: true

  def sum_component(assigns) do
    assigns = assign(assigns, sum: assigns.x + assigns.yy)
    assigns.ti

    ~H"""
    <h1><%= @title %></h1>

    <%= @sum %>
    """
  end
end
