alias LTP.App
alias LTP.Tournament

tournament_id = "tdc-2023"

:ok = App.dispatch(%Tournament.CreateTournament{
  display_name: "Tour de Cagn 2023",
  id: tournament_id
})

:ok = App.dispatch(%Tournament.CreateGame{
  id: "xo",
  display_name: "X-O",
  tournament_id: tournament_id,
  sorting: :desc
})

:ok = App.dispatch(%Tournament.CreateGame{
  id: "a-f",
  display_name: "Acqua e Fuoco",
  tournament_id: tournament_id,
  sorting: :desc
})

:ok = App.dispatch(%Tournament.CreateGame{
  id: "r-p",
  display_name: "Ricchi e Poveri",
  tournament_id: tournament_id,
  sorting: :asc
})

:ok = App.dispatch(%Tournament.CreateGame{
  id: "a-m",
  display_name: "Antico e Moderno",
  tournament_id: tournament_id,
  sorting: :asc
})
