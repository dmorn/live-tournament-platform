defmodule LTP.Tournament.CreateTournament do
  defstruct [:id, :display_name]
end

defmodule LTP.Tournament.CreatePlayer do
  defstruct [:id, :nickname, :tournament_id]
end

defmodule LTP.Tournament.CreateGame do
  defstruct [:id, :display_name, :tournament_id, sorting: :asc, comment: <<>>]
end

defmodule LTP.Tournament.AddScore do
  defstruct [:score, :player_id, :game_id, :tournament_id]
end
