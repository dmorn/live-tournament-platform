defmodule LTPWeb.Tournament.LeaderboardLive do
  use LTPWeb, :live_view
  alias LTP.Leaderboard
  alias LTP.Tournament

  def mount(%{"tournament_id" => tournament_id, "game_id" => game_id}, _session, socket) do
    {:ok, pid} = LTP.find_or_create_leaderboard(tournament_id)
    leaderboard = Leaderboard.get(pid, game_id)

    if connected?(socket) do
      Commanded.EventStore.subscribe(LTP.App, tournament_id)
    end

    {:ok,
     assign(socket,
       pid: pid,
       page_title: leaderboard.display_name,
       leaderboard: leaderboard,
       tournament_id: tournament_id,
       game_id: game_id
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
          <.button
            :if={@game_id != "general"}
            phx-click={JS.patch(~p"/tournament/#{@tournament_id}/leaderboards/#{@game_id}/add_score")}
          >
            <%= gettext("Add score") %>
          </.button>
        </:actions>
      </.header>

      <%= if Enum.any?(@leaderboard.scores) do %>
        <.table id="scores" rows={@leaderboard.scores}>
          <:col :let={score} label="#"><b><%= score.rank %></b></:col>
          <:col :let={score} label={gettext("Player")} class="w-full">
            <%= score.player.nickname %> (<%= score.player.id %>)
          </:col>
          <:col :let={score} label={gettext("Score")} class="text-right"><%= score.score %></:col>
        </.table>
      <% else %>
        <.error><%= gettext("No score has been registered yet") %></.error>
      <% end %>
    </div>

    <.modal
      :if={@live_action == :add_score}
      show
      id="modal_id"
      on_cancel={JS.patch(~p"/tournament/#{@tournament_id}/leaderboards/#{@game_id}")}
    >
      <.live_component
        module={LTPWeb.Tournament.AddScoreComponent}
        id="add-player-form"
        patch={~p"/tournament/#{@tournament_id}/leaderboards/#{@game_id}"}
        tournament_id={@tournament_id}
        game_id={@game_id}
      />
    </.modal>
    """
  end
end
