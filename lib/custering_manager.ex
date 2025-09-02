defmodule Bank.ClusteringManager do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :net_kernel.monitor_nodes(true, [:nodedown_reason])
    send(self(), :poll)
    {:ok, %{}}
  end

  def handle_info(:poll, state) do
    connect_to_tasks()
    Process.send_after(self(), :poll, 3000)
    {:noreply, state}
  end

  def handle_info({:nodeup, node, _info}, state) do
    Logger.info("Node #{node} is up")
    {:noreply, state}
  end

  def handle_info({:nodedown, node, reason}, state) do
    Logger.info("Node #{node} is down: #{reason}")
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def connect_to_tasks() do
    svc = ~c"tasks.bank"
    case :inet.getaddr(svc, :inet) do
      {:ok, _ip} ->
        connect_all(svc)
      {:error, error} ->
        Logger.error("Error getting address for #{svc}: #{error}")
        :ok
    end
  end

  def connect_all(svc) do
    case :inet.gethostbyname(svc) do
      {:ok, host} ->
        Enum.each(elem(host, 5), fn ip ->
          "bank@#{:inet.ntoa(ip)}"
          |> String.to_atom()
          |> Node.connect()
        end)

      {:error, error} ->
        Logger.error("Error getting host by name for #{svc}: #{error}")
        :ok
    end
  end
end
