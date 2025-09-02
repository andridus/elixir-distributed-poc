defmodule Bank.Application do
  use Application
  require Logger
  def start(_type, _args) do
    children = [
      {Bank.ClusteringManager, []},
      {Bank.AccountsWorker, 1000}
    ]

    opts = [strategy: :one_for_one, name: Bank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
