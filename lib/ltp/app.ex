defmodule LTP.App do
  use Commanded.Application,
    otp_app: :ltp,
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: LTP.EventStore
    ]

  router(LTP.Tournament.Router)
end
