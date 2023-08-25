# LTP
The Live Tournament Platform is ment to be used for tracking the scores of a variety
of events, be it a dart competition or a bike race. At the moment though it is tuned
to a specific tournament that this platform is going to host as first competition.

## Features
* Leaderboards live updates

## Generate an Login URL for Admins
```elixir
LTPWeb.generate_login_url("The Admin Name")
```
To login, click on the link on the desired platform.

## Setup production db
Enter the IEX session
```
fly ssh issue --agent
fly ssh console --pty -C "/app/bin/ltp remote"
```
(https://fly.io/docs/elixir/the-basics/iex-into-running-app/)

The issue the following
```elixir
config = LTP.EventStore.config()
:ok = EventStore.Tasks.Create.exec(config, [])
:ok = EventStore.Tasks.Init.exec(config, [])
```

* Populate the database with the contents of the seed file.
* To start with a clean state, change the DATABASE_URL secret and do this all over again.
