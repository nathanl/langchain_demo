defmodule LcDemo.Repo do
  use Ecto.Repo,
    otp_app: :lc_demo,
    adapter: Ecto.Adapters.Postgres
end
