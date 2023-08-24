alias LTP.App
alias LTP.Tournament

tournament_id = "tdc-2023"

:ok = App.dispatch(%Tournament.CreateTournament{
  display_name: "Tour de Cagn 2023",
  id: tournament_id
})

:ok = App.dispatch(%Tournament.CreateGame{
  id: "a-e-f",
  display_name: "Acqua e Fuoco",
  tournament_id: tournament_id,
  sorting: :desc
})
