defmodule LTP.App do
  use Commanded.Application, otp_app: :ltp

  router(LTP.Tournament.Router)
end
