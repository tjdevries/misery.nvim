defmodule MixeryWeb.IndexLive do
  use MixeryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    Hi :) For example, this.
    """
  end
end
