defmodule LTPWeb.Tournament.LeaderboardLive do
  use LTPWeb, :live_view
  alias LTP.App
  alias LTP.Leaderboard
  alias LTP.Tournament

  def mount(%{"tournament_id" => tournament_id, "game_id" => game_id}, _session, socket) do
    {:ok, pid} = LTP.find_or_create_leaderboard(tournament_id)
    leaderboard = Leaderboard.get(pid, game_id)

    if connected?(socket) and not leaderboard.is_closed do
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
    if Enum.any?(events, &(&1.data.__struct__ in [Tournament.ScoreAdded, Tournament.GameClosed])) do
      leaderboard = Leaderboard.get(socket.assigns.pid, socket.assigns.game_id)
      {:noreply, assign(socket, leaderboard: leaderboard)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("close_game", _params, socket) do
    command = %Tournament.CloseGame{tournament_id: socket.assigns.tournament_id, id: socket.assigns.game_id}

    case App.dispatch(command) do
      :ok -> {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @page_title %>

        <:actions>
          <div :if={not @leaderboard.is_closed and @game_id != "general"} class="space-x-1">
            <.button
              phx-click={
                JS.patch(~p"/tournament/#{@tournament_id}/leaderboards/#{@game_id}/add_score")
              }
            >
              <%= gettext("Add score") %>
            </.button>

            <.button
              data-confirm={gettext("Are you sure? You cannot undo this action!")}
              phx-click="close_game"
            >
              <%= gettext("Close game") %>
            </.button>
          </div>
        </:actions>
      </.header>

      <%= if Enum.any?(@leaderboard.scores) do %>
        <ul>
          <.card_with_list>
            <:item
              :for={score <- @leaderboard.scores}
              label={"#{score.rank}. #{score.player.nickname} (#{score.player.id})"}
            >
              <%= score.score %>
            </:item>
          </.card_with_list>
        </ul>
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
