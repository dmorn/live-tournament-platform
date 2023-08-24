defmodule LTP.Tournament.Router do
  use Commanded.Commands.Router

  dispatch(LTP.Tournament.CreateTournament, to: LTP.Tournament, identity: :id)
  dispatch(LTP.Tournament.CreatePlayer, to: LTP.Tournament, identity: :tournament_id)
  dispatch(LTP.Tournament.CreateGame, to: LTP.Tournament, identity: :tournament_id)
  dispatch(LTP.Tournament.CloseGame, to: LTP.Tournament, identity: :tournament_id)
  dispatch(LTP.Tournament.AddScore, to: LTP.Tournament, identity: :tournament_id)
end
