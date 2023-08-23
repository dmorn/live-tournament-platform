defmodule LTP do
  def find_or_create_leaderboard(tournament_id) do
    name = {:via, Registry, {LTP.LeaderboardRegistry, tournament_id}}

    case LTP.Leaderboard.start_link(name: name, tournament_id: tournament_id) do
      {:error, {:already_started, current_pid}} -> {:ok, current_pid}
      {:ok, pid} -> {:ok, pid}
    end
  end
end
