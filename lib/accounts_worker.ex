defmodule Bank.AccountsWorker do
  use GenServer

  # Public API
  def start_link(initial_balance) do
    GenServer.start_link(__MODULE__, initial_balance, name: __MODULE__)
  end

  def get_balance() do
    GenServer.call(__MODULE__, :get_balance)
  end

  def deposit(amount) do
    GenServer.cast(__MODULE__, {:deposit, amount})
  end

  def withdraw(amount) do
    GenServer.cast(__MODULE__, {:withdraw, amount})
  end

  # Callbacks
  def init(initial_balance) do
    {:ok, initial_balance}
  end

  def handle_call(:get_balance, _from, balance) do
    {:reply, balance, balance}
  end

  def handle_cast({:deposit, amount}, balance) do
    {:noreply, balance + amount}
  end

  def handle_cast({:withdraw, amount}, balance) do
    {:noreply, balance - amount}
  end
end
