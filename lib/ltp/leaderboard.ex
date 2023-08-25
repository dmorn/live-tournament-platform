defmodule LTP.Leaderboard do
  use GenServer

  alias LTP.Tournament

  @general_id "general"
  @general_order :asc

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

  @doc """
  Returns true if there is still a leaderboard open.
  """
  def is_open(pid) do
    summary(pid).leaderboards
    |> Enum.map(fn %{is_closed: x} -> not x end)
    |> Enum.any?()
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
      @general_id => make_leaderboard(@general_id, "Classifica Generale")
    }

    {:ok, %{boards: boards, display_name: nil, players: %{}}}
  end

  @impl true
  def handle_call({:get, leaderboard_id}, _from, state) do
    board = get_in(state, [:boards, leaderboard_id])

    response = %{
      scores: board.scores,
      display_name: board.display_name,
      is_closed: board.is_closed
    }

    {:reply, response, state}
  end

  def handle_call(:summary, _from, state) do
    leaderboards =
      state.boards
      |> Enum.sort(fn {_, %{index: left}}, {_, %{index: right}} -> left < right end)
      |> Enum.map(fn {id, board} ->
        scores = Enum.take(board.scores, 3)
        %{scores: scores, display_name: board.display_name, id: id, is_closed: board.is_closed}
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
    put_in(state, [:players, event.id], %{id: event.id, nickname: event.nickname})
  end

  defp handle_event(event = %Tournament.GameCreated{}, state) do
    board =
      make_leaderboard(
        event.id,
        event.display_name,
        map_size(state.boards),
        String.to_atom(event.sorting)
      )

    put_in(state, [:boards, event.id], board)
  end

  defp handle_event(event = %Tournament.GameClosed{}, state) do
    put_in(state, [:boards, event.id, :is_closed], true)
  end

  defp handle_event(event = %Tournament.ScoreAdded{}, state) do
    player = Map.fetch!(state.players, event.player_id)
    board = get_in(state, [:boards, event.game_id])

    score = %{
      score: event.score,
      player: player
    }

    scores =
      board.scores
      |> Enum.filter(fn score -> score.player.id != player.id end)
      |> Enum.concat([score])
      # Now that we have a raw score, add it to the leaderboard and recompute
      # the rankings.
      |> sort_scores(board.sorting)

    state
    |> put_in([:boards, event.game_id, :scores], scores)
    |> compute_general_leaderboard()
  end

  defp compute_general_leaderboard(state) do
    scores =
      state.players
      |> Enum.map(fn {_, player} -> player end)
      |> Enum.map(fn player ->
        # Only players that played at each game enter the general leaederboard.
        scores =
          state.boards
          |> Enum.filter(fn {key, _} -> key != @general_id end)
          |> Enum.map(fn {_, %{scores: scores}} ->
            Enum.find(scores, fn score -> score.player.id == player.id end)
          end)

        if Enum.all?(scores) do
          score = Enum.reduce(scores, 1, fn score, acc -> score.rank * acc end)
          %{player: player, score: score}
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> sort_scores(@general_order)

    put_in(state, [:boards, @general_id, :scores], scores)
  end

  defp sort_scores(scores, sorting) do
    scores
    |> Enum.sort(fn %{score: left}, %{score: right} ->
      case sorting do
        :desc -> left > right
        :asc -> left < right
      end
    end)
    # The same score gets the same ranking
    |> Enum.chunk_by(fn %{score: score} -> score end)
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {same_scores, index} ->
      same_scores
      |> Enum.map(&Map.put(&1, :rank, index))
    end)
  end

  defp make_leaderboard(id, name, index \\ 0, sorting \\ @general_order) do
    %{
      id: id,
      display_name: name,
      scores: [],
      sorting: sorting,
      index: index,
      is_closed: false
    }
  end
end
