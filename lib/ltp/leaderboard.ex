defmodule LTP.Leaderboard do
  use GenServer

  alias LTP.Tournament

  @general_id "general"

  def start_link(opts) do
    {opts, server_opts} = Keyword.split(opts, [:tournament_id])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc """
  Returns a summary of the tournament.
  """
  def summary(pid) do
    GenServer.call(pid, :summary)
  end

  @doc """
  Returns the scores of one leaderboard.
  """
  def get(pid, leaderboard_id) do
    GenServer.call(pid, {:get, leaderboard_id})
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
      @general_id => %{
        display_name: "General Leaderboard",
        scores: %{},
        sorting: :asc,
        index: 0
      }
    }

    {:ok, %{boards: boards, display_name: nil, players: %{}}}
  end

  @impl true
  def handle_call({:get, leaderboard_id}, _from, state) do
    board = get_in(state, [:boards, leaderboard_id])
    scores = get_sorted_scores(board)
    response = %{scores: scores, display_name: board.display_name}
    {:reply, response, state}
  end

  def handle_call(:summary, _from, state) do
    leaderboards =
      state.boards
      |> Enum.sort(fn {_, %{index: left}}, {_, %{index: right}} -> left < right end)
      |> Enum.map(fn {id, board} ->
        scores = get_sorted_scores(board) |> Enum.take(3)
        %{scores: scores, display_name: board.display_name, id: id}
      end)

    summary = %{
      display_name: state.display_name,
      leaderboards: leaderboards
    }

    {:reply, summary, state}
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
    put_in(state, [:players, event.id], event.nickname)
  end

  defp handle_event(event = %Tournament.GameCreated{}, state) do
    board = %{
      display_name: event.display_name,
      scores: %{},
      sorting: String.to_atom(event.sorting),
      index: map_size(state.boards)
    }

    put_in(state, [:boards, event.id], board)
  end

  defp handle_event(event = %Tournament.ScoreAdded{}, state) do
    player = Map.fetch!(state.players, event.player_id)
    previous_score = get_in(state, [:boards, event.game_id, :scores, event.player_id])
    attempt = if previous_score != nil, do: previous_score.attempt + 1, else: 1

    score = %{
      score: event.score,
      player: %{id: event.player_id, nickname: player},
      attempt: attempt
    }

    # Now that we have a raw score, add it to the leaderboard and recompute
    # the rankings.
    scores =
      state
      |> get_in([:boards, event.game_id])
      |> put_in([:scores, event.player_id], score)
      |> get_sorted_scores()
      |> Enum.with_index(1)
      |> Enum.map(fn {score, index} -> Map.put(score, :rank, index) end)
      |> Enum.map(fn score -> {score.player.id, score} end)
      |> Map.new()

    state
    |> put_in([:boards, event.game_id, :scores], scores)
    |> compute_general_leaderboard()
  end

  defp compute_general_leaderboard(state) do
    scores =
      state.players
      |> Enum.map(fn {id, nickname} ->
        # Only players that played at each game enter the general leaederboard.
        scores =
          state.boards
          |> Enum.filter(fn {key, _} -> key != @general_id end)
          |> Enum.map(fn {_, %{scores: scores}} -> Map.get(scores, id) end)

        if Enum.all?(scores) do
          score = Enum.reduce(scores, 1, fn score, acc -> score.rank * acc end)
          %{player: %{id: id, nickname: nickname}, score: score}
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {score, index} -> Map.put(score, :rank, index) end)
      |> Enum.map(fn score -> {score.player.id, score} end)
      |> Map.new()

    put_in(state, [:boards, @general_id, :scores], scores)
  end

  defp get_sorted_scores(leaderboard) do
    leaderboard.scores
    |> Enum.map(fn {_, score} -> score end)
    |> Enum.sort(fn %{score: left}, %{score: right} ->
      case leaderboard.sorting do
        :desc -> left > right
        :asc -> left < right
      end
    end)
  end
end
