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
       admin_id: session["admin_id"],
       add_player: false
     )}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, add_player: false)}

  def render(assigns) do
    ~H"""
    <.header>
      <%= @page_title %>

      <:actions>
        <.button :if={@admin_id != nil} phx-click="add_player">
          <%= gettext("Add player") %>
        </.button>
      </:actions>
    </.header>

    <.container>
      <.flash_group flash={@flash} />

      <.grid>
        <.card_with_list
          :for={leaderboard <- @leaderboards}
          title={leaderboard.display_name}
          phx-click={JS.navigate(~p"/tournament/#{@tournament_id}/leaderboards/#{leaderboard.id}")}
        >
          <:item :for={{score, i} <- Enum.with_index(leaderboard.scores)} class={if i == 0, do: "font-bold"} label={"#{score.rank}. #{score.player.nickname} (#{score.player.id})"}>
            <%= score.score %>
          </:item>
        </.card_with_list>
      </.grid>
    </.container>

    <.modal
      :if={@add_player}
      show
      id="modal_id"
      on_cancel={JS.patch(~p"/tournament/#{@tournament_id}", replace: true)}
    >
      <.live_component
        module={LTPWeb.Tournament.AddPlayerComponent}
        id="add-player-form"
        patch={~p"/tournament/#{@tournament_id}"}
        tournament_id={@tournament_id}
        admin_id={@admin_id}
      />
    </.modal>
    """
  end

  def handle_info({:events, events}, socket) do
    if Enum.any?(events, &(&1.data.__struct__ == Tournament.ScoreAdded)) do
      summary = Leaderboard.summary(socket.assigns.pid)
      {:noreply, assign(socket, leaderboards: summary.leaderboards)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_player", _params, socket) do
    {:noreply, assign(socket, add_player: true)}
  end
end
