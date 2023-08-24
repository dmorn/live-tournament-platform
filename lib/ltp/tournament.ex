defmodule LTP.Tournament do
  alias LTP.Tournament

  defstruct [:id, players: %{}, games: %{}]

  # Public command API

  def execute(%Tournament{id: nil}, command = %Tournament.CreateTournament{}) do
    %Tournament.TournamentCreated{id: command.id, display_name: command.display_name}
  end

  def execute(%Tournament{}, %Tournament.CreateTournament{}) do
    {:error, :tournament_already_created}
  end

  def execute(%Tournament{id: nil}, _command) do
    {:error, :tournament_not_initialized}
  end

  def execute(state, command = %Tournament.CreatePlayer{}) do
    if Map.has_key?(state.players, command.id) do
      {:error, :player_already_registered}
    else
      %Tournament.PlayerCreated{
        id: command.id,
        nickname: command.nickname,
        tournament_id: state.id
      }
    end
  end

  def execute(state, command = %Tournament.CreateGame{}) do
    cond do
      Map.has_key?(state.games, command.id) ->
        {:error, :game_already_registered}

      command.sorting not in [:asc, :desc] ->
        {:error, :invalid_sorting}

      true ->
        %Tournament.GameCreated{
          id: command.id,
          display_name: command.display_name,
          tournament_id: state.id,
          sorting: command.sorting,
          comment: command.comment
        }
    end
  end

  def execute(state, command = %Tournament.CloseGame{}) do
    %Tournament.GameClosed{id: command.id, tournament_id: state.id}
  end

  def execute(state, command = %Tournament.AddScore{}) do
    game = Map.get(state.games, command.game_id)

    cond do
      not is_number(command.score) ->
        {:error, :invalid_score}

      is_nil(game) ->
        {:error, :game_not_found}

      game.is_closed ->
        {:error, :game_is_closed}

      not Map.has_key?(state.players, command.player_id) ->
        {:error, :player_not_found}

      true ->
        %Tournament.ScoreAdded{
          score: command.score,
          player_id: command.player_id,
          game_id: command.game_id,
          tournament_id: state.id
        }
    end
  end

  # State mutators

  def apply(state, event = %Tournament.TournamentCreated{}) do
    %Tournament{state | id: event.id}
  end

  def apply(state, event = %Tournament.PlayerCreated{}) do
    %Tournament{
      state
      | players: Map.put(state.players, event.id, %{nickname: event.nickname, scores: %{}})
    }
  end

  def apply(state, event = %Tournament.GameCreated{}) do
    game = %{display_name: event.display_name, is_closed: false}
    %Tournament{state | games: Map.put(state.games, event.id, game)}
  end

  def apply(state, event = %Tournament.GameClosed{}) do
    game = %{Map.get(state.games, event.id) | is_closed: false}
    %Tournament{state | games: Map.put(state.games, event.id, game)}
  end

  def apply(state, %Tournament.ScoreAdded{}) do
    state
  end
end
