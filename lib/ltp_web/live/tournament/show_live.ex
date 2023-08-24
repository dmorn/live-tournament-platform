defmodule LTPWeb.Tournament.ShowLive do
  use LTPWeb, :live_view
  alias LTP.Leaderboard

  def mount(params, session, socket) do
    id = Map.get(params, "id", "tdc-2023")
    {:ok, pid} = LTP.find_or_create_leaderboard(id)
    summary = Leaderboard.summary(pid)

    if connected?(socket) do
      Commanded.EventStore.subscribe(LTP.App, id)
    end

    {:ok,
     assign(socket,
       page_title: summary.display_name,
       leaderboards: summary.leaderboards,
       tournament_id: id,
       is_admin: session["admin_id"] != nil
     )}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_info({:events, events}, socket) do
    if Enum.any?(events, &(&1.data.__struct__ == Tournament.ScoreAdded)) do
      leaderboard = Leaderboard.get(socket.assigns.pid, socket.assigns.game_id)
      {:noreply, assign(socket, leaderboard: leaderboard)}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @page_title %>

        <:actions>
          <.button :if={@is_admin} phx-click={JS.patch(~p"/tournament/#{@tournament_id}/add_player")}>
            <%= gettext("Add player") %>
          </.button>
        </:actions>
      </.header>

      <.grid>
        <.card_with_list
          :for={leaderboard <- @leaderboards}
          title={leaderboard.display_name}
          phx-click={JS.navigate(~p"/tournament/#{@tournament_id}/leaderboards/#{leaderboard.id}")}
        >
          <:item :for={score <- leaderboard.scores} label={"#{score.rank}. #{score.player.nickname} (#{score.player.id})"}>
            <%= score.score %>
          </:item>
        </.card_with_list>
      </.grid>
    </div>

    <.modal
      :if={@live_action == :add_player}
      show
      id="modal_id"
      on_cancel={JS.patch(~p"/tournament/#{@tournament_id}")}
    >
      <.live_component
        module={LTPWeb.Tournament.AddPlayerComponent}
        id="add-player-form"
        patch={~p"/tournament/#{@tournament_id}"}
        tournament_id={@tournament_id}
      />
    </.modal>
    """
  end
end
