defmodule LTP.TournamentTest do
  use LTP.InMemoryEventStoreCase

  alias LTP.{App, Tournament, Leaderboard}

  setup do
    tournament_id = "tdc-2023"
    game_id = "a&f"
    nickname = "Ciuck"
    player_id = 1

    :ok =
      App.dispatch(%Tournament.CreateTournament{
        display_name: "Tour de Cagn 2023",
        id: tournament_id
      })

    :ok =
      App.dispatch(%Tournament.CreateGame{
        id: game_id,
        display_name: "Acqua e Fuoco",
        tournament_id: tournament_id,
        sorting: :desc
      })

    :ok =
      App.dispatch(%LTP.Tournament.CreatePlayer{
        nickname: nickname,
        id: player_id,
        tournament_id: tournament_id
      })

    %{tournament_id: tournament_id, game_id: game_id, player_id: player_id, nickname: nickname}
  end

  test "scores are reflected in the leaderboard", ctx do
    score = 100

    :ok =
      App.dispatch(%Tournament.AddScore{
        score: score,
        game_id: ctx.game_id,
        tournament_id: ctx.tournament_id,
        player_id: ctx.player_id
      })

    {:ok, pid} = LTP.find_or_create_leaderboard(ctx.tournament_id)

    id = ctx.player_id
    nick = ctx.nickname

    assert [
             %{rank: 1, player: %{id: ^id, nickname: ^nick}, score: ^score}
           ] = Leaderboard.get(pid, ctx.game_id).scores

    assert [
             %{rank: 1, player: %{id: ^id, nickname: ^nick}}
           ] = Leaderboard.get(pid, :general).scores

    # Now check the scores again when a new player gets in.
    other_id = 2
    other_score = 99
    other_nick = "Other"

    :ok =
      App.dispatch(%LTP.Tournament.CreatePlayer{
        nickname: other_nick,
        id: other_id,
        tournament_id: ctx.tournament_id
      })

    :ok =
      App.dispatch(%Tournament.AddScore{
        score: other_score,
        game_id: ctx.game_id,
        tournament_id: ctx.tournament_id,
        player_id: other_id
      })

    assert [
             %{rank: 1, player: %{id: ^id, nickname: ^nick}, score: ^score},
             %{rank: 2, player: %{id: ^other_id, nickname: ^other_nick}, score: ^other_score}
           ] = Leaderboard.get(pid, ctx.game_id).scores

    assert [
             %{rank: 1, player: %{id: ^id, nickname: ^nick}},
             %{rank: 2, player: %{id: ^other_id, nickname: ^other_nick}}
           ] = Leaderboard.get(pid, :general).scores
  end
end
