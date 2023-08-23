defmodule LTP.Leaderboard do
  use GenServer

  alias LTP.Tournament

  def start_link(opts) do
    {opts, server_opts} = Keyword.split(opts, [:tournament_id])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  def get(pid, leaderboard_id) do
    GenServer.call(pid, {:get, leaderboard_id})
  end

  @impl true
  def handle_call({:get, leaderboard_id}, _from, state) do
    {:reply, get_in(state, [:boards, leaderboard_id]), state}
  end

  @impl true
  def handle_info({:events, events}, state) do
    state =
      Enum.reduce(events, state, fn event, state ->
        handle_event(event.data, state)
      end)

    {:noreply, state}
  end

  defp handle_event(event = %Tournament.TournamentCreated{}, state) do
    %{state | display_name: event.display_name}
  end

  defp handle_event(event = %Tournament.PlayerCreated{}, state) do
    new_player = %{id: event.id, nickname: event.nickname}

    players =
      Enum.sort([new_player | state.players], fn %{id: left}, %{id: right} ->
        left < right
      end)

    %{state | players: players}
  end

  defp handle_event(event = %Tournament.GameCreated{}, state) do
    put_in(state, [:boards, event.id], %{
      display_name: event.display_name,
      scores: [],
      sorting: event.sorting
    })
  end

  defp handle_event(event = %Tournament.ScoreAdded{}, state) do
    player = Enum.find(state.players, fn player -> player.id == event.player_id end)

    if is_nil(player) do
      raise "could not find player #{inspect(player)} in leaderboard's state"
    end

    sorting = Map.fetch!(state.boards, event.game_id).sorting

    update_in(state, [:boards, event.game_id, :scores], fn scores ->
      [%{score: event.score, player: player} | scores]
      |> Enum.sort(fn %{score: left}, %{score: right} ->
        case sorting do
          "asc" -> left < right
          "desc" -> left > right
        end
      end)
      |> Enum.with_index(1)
      |> Enum.map(fn {score, index} -> Map.put(score, :rank, index) end)
    end)
    |> compute_general_leaderboard()
  end

  defp compute_general_leaderboard(state) do
    leaderboard =
      state.players
      |> Enum.map(fn player ->
        # Only players that played at each game enter the general leaederboard.
        scores =
          state.boards
          |> Enum.filter(fn {key, _} -> key != :general end)
          |> Enum.map(fn {_, %{scores: scores}} ->
            Enum.find(scores, fn score ->
              score.player.id == player.id
            end)
          end)

        if Enum.all?(scores) do
          score = Enum.reduce(scores, 1, fn score, acc -> score.rank * acc end)
          %{player: player, score: score}
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort(fn %{score: left}, %{score: right} -> left < right end)
      |> Enum.with_index(1)
      |> Enum.map(fn {score, index} -> Map.put(score, :rank, index) end)

    put_in(state, [:boards, :general, :scores], leaderboard)
  end

  @impl true
  def init(opts) do
    # Restore state
    LTP.App
    |> Commanded.EventStore.stream_forward(opts[:tournament_id], 0)
    |> Enum.each(fn event ->
      send(self(), {:events, [event]})
    end)

    Commanded.EventStore.subscribe(LTP.App, opts[:tournament_id])

    boards = %{
      general: %{display_name: "General", scores: [], sorting: :desc}
    }

    {:ok, %{boards: boards, display_name: nil, players: []}}
  end
end
