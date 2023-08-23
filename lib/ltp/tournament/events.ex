defmodule LTP.Tournament.TournamentCreated do
  @derive Jason.Encoder
  defstruct [:id, :display_name]
end

defmodule LTP.Tournament.PlayerCreated do
  @derive Jason.Encoder
  defstruct [:id, :nickname, :tournament_id]
end

defmodule LTP.Tournament.GameCreated do
  @derive Jason.Encoder
  defstruct [:id, :display_name, :tournament_id]
end

defmodule LTP.Tournament.ScoreAdded do
  @derive Jason.Encoder
  defstruct [:score, :player_id, :game_id, :tournament_id]
end
