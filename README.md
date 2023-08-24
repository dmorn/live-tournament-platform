# LTP

## Generate an Admin token
```elixir
Phoenix.Token.sign(LTPWeb.Endpoint, "auth", "philip")
```

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

## Phoenix
To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
