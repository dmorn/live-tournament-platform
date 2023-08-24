defmodule LTPWeb.Tournament.LeaderboardLive do
  use LTPWeb, :live_view
  alias LTP.App
  alias LTP.Leaderboard
  alias LTP.Tournament

  def mount(%{"tournament_id" => tournament_id, "game_id" => game_id}, session, socket) do
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
       game_id: game_id,
       admin_id: session["admin_id"],
       add_score: false
     )}
  end

  def render(assigns) do
    ~H"""
    <.header />

    <.container>
      <div :if={not @leaderboard.is_closed and @game_id != "general" and @admin_id != nil} class="space-y-1 mb-6 flex flex-col">
        <.button
          phx-click="add_score"
          class="justify-center"
        >
          <%= gettext("Add score") %>
        </.button>

        <.button
          :if={false # Disable the close  button for now. There is no reopen action yet}
          data-confirm={gettext("Are you sure? You cannot undo this action!")}
          phx-click="close_game"
          class="justify-center"
        >
          <%= gettext("Close game") %>
        </.button>
      </div>

      <.flash_group flash={@flash} />

      <%= if Enum.any?(@leaderboard.scores) do %>
        <ul>
          <.card_with_list title={@page_title}>
            <:item
              :for={{score, i} <- Enum.with_index(@leaderboard.scores)}
              class={if i < 3, do: "font-bold"}
              label={"#{score.rank}. #{score.player.nickname} (#{score.player.id})"}
            >
              <%= score.score %>
            </:item>
          </.card_with_list>
        </ul>
      <% else %>
        <.error><%= gettext("No score has been registered yet") %></.error>
      <% end %>
    </.container>

    <.modal
      :if={@add_score}
      show
      id="modal_id"
      on_cancel={JS.patch(~p"/tournament/#{@tournament_id}/leaderboards/#{@game_id}", replace: true)}
    >
      <.live_component
        module={LTPWeb.Tournament.AddScoreComponent}
        id="add-player-form"
        patch={~p"/tournament/#{@tournament_id}/leaderboards/#{@game_id}"}
        tournament_id={@tournament_id}
        admin_id={@admin_id}
        game_id={@game_id}
      />
    </.modal>
    """
  end

  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, add_score: false)}

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

    case App.dispatch(command, metadata: %{admin_id: socket.assigns.admin_id}) do
      :ok -> {:noreply, socket}
    end
  end

  def handle_event("add_score", _params, socket) do
    {:noreply, assign(socket, add_score: true)}
  end
end
